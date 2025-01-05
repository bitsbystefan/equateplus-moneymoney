"""
Showcase for EquatePlus scrapping

Please provide:
- credentials.txt: username and password separated by newline

Please act during verify_qr_code:
- equateplus_qr.png: Scan QR code with EquateAccess app
"""
from base64 import b64decode
from pathlib import Path
from random import randint
from time import sleep

import requests


CREDENTIALS_PATH: Path = Path("credentials.txt")
QR_CODE_PATH: Path = Path("equateplus_qr.png")

CREDENTIALS: list[str] = CREDENTIALS_PATH.read_text().strip().split("\n")


def debug(func):
    def wrapper(*args, **kwargs):
        print(func.__name__, end=" ", flush=True)
        result = func(*args, **kwargs)
        print("->", result)
        sleep(0.5)
        return result
    return wrapper


def random_digits(n):
    range_start = 10**(n-1)
    range_end = (10**n)-1
    return randint(range_start, range_end)


def get_data(data: dict, keys: tuple[str, ...]) -> str:
    for key in keys:
        if key in data and data[key] is not None:
            return data[key]


def get_name(data: dict) -> str:
    return get_data(data, ("VEHICLE", "VEHICLE_DESCRIPTION"))


def get_amount(data: dict) -> float:
    quantity = get_data(data, ("QUANTITY", "AVAIL_QTY", "LOCKED_QTY", "LOCKED_PERF_QTY"))
    if quantity is None:
        return None
    return quantity["amount"]


class Equate:
    def __init__(self) -> None:
        self.session: requests.Session = requests.Session()
        self.cookies: dict[str, str] = {}
        self.csrf: str | None = None
        self.csrf2: str | None = None
        self.device_id: str | None = None
        self.session_id: str | None = None
        self.cid: str = "eqp." + str(random_digits(7))
        self.plan_ids: list[str] = []
        self.securities: dict[str, float] = {}

        self.session.hooks.update({
            "response": [
                self.set_csrf,
            ],
        })

    def set_csrf(self, response: requests.Response, **kwargs) -> None:
        prefix = b"csrfRegisterAjax(\"csrfpId\", \""
        if prefix in response.content:
            self.csrf = response.content.split(prefix)[1].split(b"\")")[0].decode("utf-8")
            self.session.headers["csrfpId"] = self.csrf

        prefix = b",\"equateCsrfToken2\":\""
        if prefix in response.content:
            self.session.headers["EQUATE-CSRF2-TOKEN-PARTICIPANT2"] = response.content.split(prefix)[1].split(b"\",")[0].decode("utf-8")

    def ids(self) -> dict[str, str]:
        return {
            "_cId": self.cid,
            "_rId": str(random_digits(8)),
        }

    @debug
    def initialize(self) -> bool:
        response: requests.Response = self.session.get(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
        )
        
        return b"isiwebuserid" in response.content

    @debug
    def send_user(self) -> bool:
        response: requests.Response = self.session.post(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
            params={
                "csrfpId": self.csrf,
            },
            data={
                "csrfpId": self.csrf,
                "isiwebuserid": CREDENTIALS[0],
                "result": "Continue Login",
            },
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },)
        return b"isiwebpasswd" in response.content

    @debug
    def send_credentials(self) -> bool:
        response: requests.Response = self.session.post(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
            data={
                "csrfpId": self.csrf,
                "isiwebuserid": CREDENTIALS[0],
                "isiwebpasswd": CREDENTIALS[1],
                "result": "Continue",
            },
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        return b"EquateAccess app" in response.content

    @debug
    def request_devices(self) -> bool:
        response: requests.Response = self.session.post(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
            data={
                "isiwebuserid": CREDENTIALS[0],
                "isiwebpasswd": "null",
                "result": "null",
            },
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        try:
            self.device_id = response.json()["dispatchTargets"][0]["id"]
            return True
        except (KeyError, IndexError):
            return False

    @debug
    def request_qr_code(self) -> bool:
        response: requests.Response = self.session.get(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
            params={
                "o.dispatchTargetId.v": self.device_id,
                **self.ids(),
            },
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        try:
            data = response.json()
            QR_CODE_PATH.write_bytes(b64decode(data["dispatcherInformation"]["response"] + "=="))
            self.session_id = data["sessionId"]

            return True
        except (KeyError, IndexError):
            return False

    @debug
    def verify_qr_code(self) -> bool:
        while True:
            sleep(1.0)
            response: requests.Response = self.session.get(
                "https://www.equateplus.com/EquatePlusParticipant2/?login",
                params={
                    "o.fidoUafSessionId.v": self.session_id,
                    **self.ids(),
                },
                headers={
                    "Content-Type": "application/x-www-form-urlencoded",
                },
            )
            
            print(".", end="", flush=True)

            try:
                result = response.json()["status"]
            except (KeyError, IndexError):
                print(response.content)
                break
            if result in ("succeeded", "failed_retry_please", "failed"):
                break

        print(" ", end="", flush=True)
        return result == "succeeded"

    @debug
    def complete_login(self) -> bool:
        response: requests.Response = self.session.post(
            "https://www.equateplus.com/EquatePlusParticipant2/?login",
            data={
                "result": "Continue",
            },
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        return b"TopLoaderSkeleton" in response.content

    @debug
    def get_plan_summary(self) -> bool:
        response: requests.Response = self.session.get(
            "https://www.equateplus.com/EquatePlusParticipant2/services/planSummary/get",
            params=self.ids(),
        )

        try:
            data = response.json()
            self.plan_ids = [plan["id"] for plan in data["entries"]]
            return not data["empty"]
        except (KeyError, IndexError):
            return False

    @debug
    def get_plan_details(self) -> bool:
        for plan_id in self.plan_ids:
            response: requests.Response = self.session.post(
                "https://www.equateplus.com/EquatePlusParticipant2/services/planDetails/get",
                params=self.ids(),
                json={
                    "$type": "EntityIdentifier",
                    "id": plan_id,
                },
            )
            print(".", end="", flush=True)
            try:
                for plan_groups in response.json()["entries"]:
                    for plan_details in plan_groups["entries"]:
                        for value in plan_details["entries"]:
                            name = get_name(value)
                            amount = get_amount(value)
                            if amount is None:
                                continue
                            self.securities[name] = self.securities.get(name, 0) + amount
            except (KeyError, IndexError):
                return False

        print(" ", end="", flush=True)
        return True

    @debug
    def logout(self) -> None:
        self.session.get(
            "https://www.equateplus.com/EquatePlusParticipant2/services/participant/logout",
        )


def main() -> None:
    e = Equate()
    try:
        e.initialize() and \
        e.send_user() and \
        e.send_credentials() and \
        e.request_devices() and \
        e.request_qr_code() and \
        e.verify_qr_code() and \
        e.complete_login() and \
        e.get_plan_summary() and \
        e.get_plan_details()
    finally:
        e.logout()

    from pprint import pprint
    pprint(e.securities)


if __name__ == "__main__":
    main()

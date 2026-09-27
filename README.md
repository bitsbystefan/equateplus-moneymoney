# EquatePlus SE Edition plugin for MoneyMoney

A quick and dirty plugin for MoneyMoney for share depot - specifically for Equate Plus SE depots.
This is a pure personal and private project and has absolutely no relationship to any company - but might be usefull for SE employees.

It may work or not work for other depots.

~~Released version is now signed and will run in released versions of the MoneyMoney App.~~ **Outdated:** The current modified script is no longer officially signed.

### Updated script and digital signature

Changes to this script invalidate its official digital signature. Until a new signature is obtained, disable signature verification in MoneyMoney: **Settings → Extensions → “Digitale Signatur von Extensions deaktivieren”**. This is a temporary workaround while the updated script is monitored in personal use for 2–3 weeks; a new signature will be requested after that period.

## Requirements

* MoneyMoney 2.4.72 or later. The QR/FIDO login uses MoneyMoney's native QR challenge and polling support. MoneyMoney 2.5.3 satisfies this requirement.

## Authentication

The plugin supports the EquatePlus login methods offered for the account:

* **EquateAccess app (QR/FIDO):** Install **EquateAccess** from the App Store. MoneyMoney displays the QR challenge; scan it with the app and confirm the request. The plugin waits for the confirmation.
* **SMS one-time code (OTP):** Enter the code sent to the registered mobile number when MoneyMoney prompts for it.

The authentication flow uses EquatePlus's `EquatePlusParticipant2` login and CSRF/session handling. EquatePlus determines which authentication method is offered.

Portfolio and price parsing remain specific to the SE edition of this plugin.


## ToDos

* Union the inital fork and the SE Edition to have one version of the EquatePlus extension
* Patches, Updates etc. may not be signed immediately  - you need to allow unsigned extensions.


## Credits 

Forked from Michael-Beutling as my specific depot requires different mapping.
Really all I changed was the mapping - so main credits to go to Michael-Beutling.

The QR/FIDO and SMS authentication flow is adapted from the login implementation in [neatc0der/equateplus-moneymoney](https://github.com/neatc0der/equateplus-moneymoney), which credits neatc0der and DerSchiman.

For all changes done by me, the MIT License applies. For original license, please visit:
https://github.com/Michael-Beutling/equateplus-moneymoney


## The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

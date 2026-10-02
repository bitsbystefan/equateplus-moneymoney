# EquatePlus SE Extension for MoneyMoney

A MoneyMoney extension for synchronizing EquatePlus employee share plan positions. This edition is configured for SE plans; other company-specific plans may not work.

This is an independent personal project and is not affiliated with EquatePlus, MoneyMoney, or any employer.

## Features

- Portfolio synchronization with MoneyMoney
- PDF statement downloads from the EquatePlus document library
- EquateAccess app authentication (QR/FIDO)
- SMS one-time code (OTP) authentication

## Account types

- **EquatePlus SE:** Individual positions
- **EquatePlus SE (cumulative):** Positions aggregated by security

## Requirements

- MoneyMoney 2.4.72 or later. QR/FIDO authentication uses MoneyMoney's native QR challenge and polling support.
- An active EquatePlus participant account

## Installation

1. Place `EquatePlus.lua` in MoneyMoney's Extensions folder. To find the folder, open **Help → Show Database in Finder** in MoneyMoney.
2. Restart MoneyMoney.
3. Add a new account and search for **EquatePlus SE**.

## Authentication

The extension supports the login methods offered for your EquatePlus account:

- **EquateAccess app (QR/FIDO):** Install EquateAccess from the App Store, scan the QR code shown by MoneyMoney, and approve the request in the app.
- **SMS one-time code (OTP):** Enter the code sent to your registered mobile number when MoneyMoney prompts for it.

EquatePlus determines which authentication method is available for your account.

## Digital signature

This modified script is not officially signed. If MoneyMoney's signature verification blocks it, disable signature verification under **Settings → Extensions → “Digitale Signatur von Extensions deaktivieren”**. Disabling signature verification affects extension signature checks in MoneyMoney, so re-enable it when you no longer need to run unsigned extensions.

## Credits and license

This extension is forked from [Michael-Beutling's EquatePlus extension](https://github.com/Michael-Beutling/equateplus-moneymoney). The portfolio mapping was adapted for SE plans.

The QR/FIDO and SMS authentication flow and PDF statement download are adapted from [neatc0der/equateplus-moneymoney](https://github.com/neatc0der/equateplus-moneymoney), which credits neatc0der and DerSchiman.

Changes made for this SE edition are offered under the MIT License below. Original portions retain their upstream licensing and attribution terms; see [Michael-Beutling's repository](https://github.com/Michael-Beutling/equateplus-moneymoney).

## MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

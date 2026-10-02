local url="https://www.equateplus.com/EquatePlusParticipant2/?login"

local baseurl=""
local reportOnce
local Version="1.17"
local CSRF_TOKEN=nil
local CSRF2_TOKEN=nil
local csrfpId=nil
local connection
local debugging=false
local nosecrets=false
local cummulate=false
local html

local dcHost="https://www.equateplus.com"
local cId="eqp."..tostring(math.random(10000000,99999999))
local session_id=nil
local awaitingOtp=false
local otpPageHtml=nil

local function randomId()
  return tostring(math.random(10000000,99999999))
end

local function urlEncode(value)
  value=tostring(value or "")
  return (value:gsub("([^%w%-%.%_%~ ])", function(c)
    return string.format("%%%02X", string.byte(c))
  end):gsub(" ", "+"))
end

local function normalizeUrl(value)
  value=value or ""
  if string.match(value,"^https?://") then return value end
  if string.sub(value,1,1)=="?" then return dcHost.."/EquatePlusParticipant2/"..value end
  if string.sub(value,1,1)=="/" then return dcHost..value end
  if baseurl=="" then return dcHost.."/"..value end
  return baseurl..value
end

function connectWithCSRF(method, url, postContent, postContentType, headers)
  local requestUrl, requestMethod, body, contentType, requestHeaders
  if type(method)~="string" then
    local req=method or {}
    requestUrl=normalizeUrl(req.url or url)
    requestMethod=req.method or "GET"
    body=req.postContent or req.body or postContent or ""
    contentType=req.postContentType or req.mimeType or postContentType or "application/x-www-form-urlencoded"
    requestHeaders={}
    for k,v in pairs(req.headers or {}) do requestHeaders[k]=v end
    for k,v in pairs(headers or {}) do requestHeaders[k]=v end
  else
    requestUrl=normalizeUrl(url)
    requestMethod=method
    body=postContent or ""
    contentType=postContentType or "application/json"
    requestHeaders={}
    for k,v in pairs(headers or {}) do requestHeaders[k]=v end
  end
  requestHeaders["Accept"]=requestHeaders["Accept"] or "*/*"
  if string.find(requestUrl,"?login",1,true) then
    requestHeaders["Accept"]="application/json, text/plain, */*"
    requestHeaders["X-Requested-With"]=requestHeaders["X-Requested-With"] or "XMLHttpRequest"
    requestHeaders["Referer"]=requestHeaders["Referer"] or (dcHost.."/eqlogin/")
  elseif string.find(requestUrl,"/EquatePlusParticipant2/services/",1,true) then
    requestHeaders["Referer"]=requestHeaders["Referer"] or (dcHost.."/EquatePlusParticipant2/")
  end
  if CSRF_TOKEN then requestHeaders["csrfpId"]=CSRF_TOKEN end
  if CSRF2_TOKEN then requestHeaders["EQUATE-CSRF2-TOKEN-PARTICIPANT2"]=CSRF2_TOKEN end
  local content, charset, mimeType, filename, responseHeaders = connection:request(
    requestMethod, requestUrl, body, contentType, requestHeaders)
  local response=content or ""
  local token=string.match(response,'"csrfpId"%s*:%s*"([^"]+)"')
  if not token then token=string.match(response,'csrfRegisterAjax%(%s*"csrfpId"%s*,%s*"([^"]+)"') end
  if not token then token=string.match(response,'csrfModifyLinks%(%s*"csrfpId"%s*,%s*"([^"]+)"') end
  if token and token~="" then CSRF_TOKEN=token; csrfpId=token end
  local token2=string.match(response, "['\"]equateCsrfToken2['\"]%s*:%s*['\"]([^'\"]+)['\"]")
  if not token2 then token2=string.match(response, "name=['\"]EQUATE%-CSRF2%-TOKEN%-PARTICIPANT2['\"]%s+value=['\"]([^'\"]+)['\"]") end
  if token2 and token2~="" then CSRF2_TOKEN=token2 end
  if responseHeaders and responseHeaders["CSRF_TOKEN"] then CSRF_TOKEN=responseHeaders["CSRF_TOKEN"] end
  return response
end

WebBanking{version=Version, url=url,services    = {"EquatePlus SE","EquatePlus SE (cumulative)"},
  description = "SE Depot von EquatePlus"}


function SupportsBank (protocol, bankCode)
  return  protocol == ProtocolWebBanking and (bankCode == "EquatePlus SE"  or bankCode == "EquatePlus SE (cumulative)")
end

function lprint(text)
  repeat
    print("  ",string.sub(text,1,60))
    text=string.sub(text,61)
  until text == ''
end

function tprint (tbl, indent)
  if debugging then
    if not indent then indent = 3 end
    for k, v in pairs(tbl) do
      formatting = string.rep(" ", indent) .. k .. ": "
      if nosecrets and (type(v) == 'string') then
        print(formatting .. type(v).."'"..v.."'")
      else
        print(formatting .. type(v))
      end
      if type(v) == 'table' and indent < 9 then tprint(v,indent+3) end
    end
  end
end

function InitializeSession2 (protocol, bankCode, step, credentials, interactive)
  if step==1 then
    baseurl=""
    debugging=false
    nosecrets=false
    cummulate=(bankCode=="EquatePlus SE (cumulative)")
    CSRF_TOKEN=nil
    CSRF2_TOKEN=nil
    csrfpId=nil
    session_id=nil
    awaitingOtp=false
    otpPageHtml=nil
    cId="eqp."..randomId()
    dcHost="https://www.equateplus.com"
    connection=Connection()

    local username=credentials[1]
    local password=credentials[2]
    if string.sub(username,1,1)=="#" then
      print("Debugging, remove # char from username!")
      username=string.sub(username,2)
      debugging=true
    end
    if string.sub(username,1,1)=="#" then
      print("Debugging, remove # chars from username!")
      username=string.sub(username,2)
      nosecrets=true
    end

    local function hasLoginForm(doc)
      return doc:xpath("//*[@id='loginForm']"):length()>0 or
        doc:xpath("//input[@name='isiwebuserid']"):length()>0
    end
    local function loadLogin(target)
      return HTML(connectWithCSRF("GET",target))
    end

    html=loadLogin(url)
    if not hasLoginForm(html) then
      local candidates={
        "https://www.emea.equateplus.com/EquatePlusParticipant2/?login",
        "https://www.na.equateplus.com/EquatePlusParticipant2/?login"
      }
      for _,target in ipairs(candidates) do
        dcHost=string.match(target,"^(https?://[^/]+)") or dcHost
        local candidate=loadLogin(target)
        if hasLoginForm(candidate) then html=candidate; break end
      end
    end
    if not hasLoginForm(html) then return "EquatePlus plugin error: No login mask found!" end

    html:xpath("//*[@id='eqUserId']"):attr("value",username)
    html:xpath("//*[@id='submitField']"):attr("value","Continue Login")
    html=HTML(connectWithCSRF(html:xpath("//*[@id='loginForm']"):submit()))
    if not hasLoginForm(html) then return "EquatePlus plugin error: No login mask found!" end

    local postBody="isiwebuserid="..urlEncode(username)..
      "&isiwebpasswd="..urlEncode(password).."&result=Continue"
    if CSRF_TOKEN then postBody=postBody.."&csrfpId="..urlEncode(CSRF_TOKEN) end
    local content=connectWithCSRF("POST",dcHost.."/EquatePlusParticipant2/?login",
      postBody,"application/x-www-form-urlencoded")
    html=HTML(content)

    if string.find(content,'id="otpCodeId"',1,true) or
       string.find(content,'class="otpCodeSms"',1,true) or
       string.find(content,"Security Step Code",1,true) then
      awaitingOtp=true
      otpPageHtml=html
      return {title="Security Code", challenge="Please enter the SMS code.", label="Code", password=true}
    end

    local response=connectWithCSRF("POST", "?login&_cId="..cId.."&_rId="..randomId(),
      "isiwebuserid="..urlEncode(username).."&isiwebpasswd=null&result=null",
      "application/x-www-form-urlencoded")
    local ok, auth=pcall(function() return JSON(response):dictionary() end)
    if not ok or not auth or not auth["dispatchTargets"] or not auth["dispatchTargets"][1] then
      -- Some legacy accounts finish directly after the password form.
      if hasLoginForm(html) then return "EquatePlus: Unbekannter oder nicht unterstützter Login-Schritt." end
      baseurl=dcHost.."/EquatePlusParticipant2/"
      return nil
    end
    local target=auth["dispatchTargets"][1]
    local qr=JSON(connectWithCSRF("GET", "?login&o.dispatchTargetId.v="..urlEncode(target["id"])..
      "&_cId="..cId.."&_rId="..randomId())):dictionary()
    if not qr or not qr["sessionId"] or not qr["dispatcherInformation"] then
      return "EquatePlus: QR/FIDO-Anmeldeaufforderung konnte nicht geladen werden."
    end
    session_id=qr["sessionId"]
    baseurl=dcHost.."/EquatePlusParticipant2/"
    return {title=target["name"] or "EquateAccess App", challenge=qr["dispatcherInformation"]["response"],
      poll=true, tanMethod={name="QR-Code"}}
  end

  if awaitingOtp and otpPageHtml then
    local otp=credentials and (credentials[1] or credentials["otp"] or credentials["tan"])
    if not otp or otp=="" then
      return {title="Security Code", challenge="Please enter the SMS code.", label="Code", password=true}
    end
    otpPageHtml:xpath("//*[@id='otpCodeId']"):attr("value",otp)
    otpPageHtml:xpath("//*[@id='submitField']"):attr("value","verify")
    local content=connectWithCSRF(otpPageHtml:xpath("//*[@id='loginForm']"):submit())
    local after=HTML(content)
    local errorText=after:xpath("//*[@id='OtpErrorMsg']"):text()
    if errorText=="" then errorText=after:xpath("//*[@id='ErrorMsg']"):text() end
    if errorText~="" or string.find(content,'id="otpCodeId"',1,true) then
      return "EquatePlus: "..(errorText~="" and errorText or "SMS-Code wurde nicht bestätigt.")
    end
    awaitingOtp=false
    otpPageHtml=nil
    connectWithCSRF("POST","?login&_cId="..cId.."&_rId="..randomId(),"result=Continue","application/x-www-form-urlencoded")
    connectWithCSRF("GET","/EquatePlusParticipant2/")
    baseurl=dcHost.."/EquatePlusParticipant2/"
    return nil
  end

  if session_id then
    for _=1,30 do
      local status=JSON(connectWithCSRF("GET", "?login&o.fidoUafSessionId.v="..urlEncode(session_id)..
        "&_cId="..cId.."&_rId="..randomId())):dictionary()
      if status and status["status"]=="succeeded" then
        connectWithCSRF("POST","?login&_cId="..cId.."&_rId="..randomId(),"result=Continue","application/x-www-form-urlencoded")
        connectWithCSRF("GET","/EquatePlusParticipant2/")
        baseurl=dcHost.."/EquatePlusParticipant2/"
        session_id=nil
        return nil
      elseif status and status["status"]=="failed_retry_please" then
        return "EquatePlus: Bitte Anmeldung erneut starten."
      elseif status and status["status"]=="failed" then
        return "EquatePlus: App-Authentifizierung fehlgeschlagen."
      end
      MM.sleep(1)
    end
    return "EquatePlus: Bestätigung in der App wurde nicht rechtzeitig erkannt."
  end
  return "EquatePlus: Anmeldestatus ist verloren gegangen; bitte erneut anmelden."
end

function ListAccounts (knownAccounts)
  local user=JSON(connectWithCSRF("GET","services/user/get")):dictionary()

  if debugging then tprint (user) end
  -- Return array of accounts.
  reportOnce=true
  local account
  local status,err = pcall( function()
    account = {
      name = "Equateplus "..user["companyId"],
      --owner = user["participant"]["firstName"]["displayValue"].." "..user["participant"]["lastName"]["displayValue"],
      accountNumber = user["participant"]["userId"],
      bankCode = "equatePlus",
      currency = user["reportingCurrency"]["code"],
      portfolio = true,
      type = AccountTypePortfolio
    }
  end)--pcall
  bugReport(status,err,user)
  return {account}
end

function RefreshAccount (account, since)
  local summary=JSON(connectWithCSRF("GET","services/planSummary/get")):dictionary()
  if debugging then tprint (summary) end
  local securities = {}
  reportOnce=true
  local status,err = pcall( function()
    for k,v in pairs(summary["entries"]) do
      local details=JSON(connectWithCSRF("POST","services/planDetails/get","{\"$type\":\"EntityIdentifier\",\"id\":\""..v["id"].."\"}")):dictionary()
      if debugging then tprint (details) end
      local status,err = pcall( function()
        for k,v in pairs(details["entries"]) do
          local status,err = pcall( function()
            for k,v in pairs(v["entries"]) do
              local status,err = pcall( function()
                local marketName=v["marketName"]
                local marketPrice=v["marketPrice"]["amount"]
                for k,v in pairs(v["entries"]) do
                  local status,err = pcall( function()
                    -- SE Edition: COST_BASIS -> SELL_PURCHASE_PRICE
                    if(v["SELL_PURCHASE_PRICE"])then
                     -- "date": "2016-02-12T00:00:00.000",
                     -- SE Edition: ALLOC_DATE -> TRANSACTION_DATE
                     local year,month,day=v["TRANSACTION_DATE"]["date"]:match ( "^(%d%d%d%d)%-(%d%d)%-(%d%d)")
                     --print (year.."-"..month.."-"..day)
                     if(year)then
                       tradeTimestamp=os.time({year=year,month=month,day=day})
                     end
                     local qty=0
                     -- SE Edition: AVAIL_QTY -> QUANTITY
                     if v["QUANTITY"] and v["QUANTITY"]["amount"] then
                       qty=v["QUANTITY"]["amount"]
                     end

                     if v["LOCKED_QTY"] and v["LOCKED_QTY"]["amount"] then
                       qty=qty+v["LOCKED_QTY"]["amount"]
                     end
                      local security={
                        -- String name: Bezeichnung des Wertpapiers
                        -- SE Edition: VEHICLE_DESCRIPTION -> VEHICLE
                        name=v["VEHICLE"],

                        -- String isin: ISIN
                        -- String securityNumber: WKN
                        -- String market: Börse
                        market=marketName,

                        -- String currency: Währung bei Nominalbetrag oder nil bei Stückzahl
                        -- Number quantity: Nominalbetrag oder Stückzahl
                        quantity=qty,

                        -- Number amount: Wert der Depotposition in Kontowährung
                        -- Number originalCurrencyAmount: Wert der Depotposition in Originalwährung
                        -- Number exchangeRate: Wechselkurs

                        -- Number tradeTimestamp: Notierungszeitpunkt; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
                        tradeTimestamp=tradeTimestamp,

                        -- Number price: Aktueller Preis oder Kurs
                        price=marketPrice,

                        -- String currencyOfPrice: Von der Kontowährung abweichende Währung des Preises.
                        -- Number purchasePrice: Kaufpreis oder Kaufkurs
                        -- SE Edition: COST_BASIS -> SELL_PURCHASE_PRICE
                        purchasePrice=v["SELL_PURCHASE_PRICE"]["amount"],

                      -- String currencyOfPurchasePrice: Von der Kontowährung abweichende Währung des Kaufpreises.

                      }
                      if cummulate then
                        -- SE Edition: VEHICLE_DESCRIPTION -> VEHICLE
                        name='_'..v["VEHICLE"]
                        if securities[name] == nil then
                          security['sumPrice']=security['purchasePrice']*qty
                          securities[name]=security
                          table.insert(securities,security)
                        else
                          securities[name]['sumPrice']=securities[name]['sumPrice']+security['purchasePrice']*qty
                          securities[name]['quantity']=securities[name]['quantity']+qty
                          securities[name]['purchasePrice']=securities[name]['sumPrice']/securities[name]['quantity']
                        end
                      else
                        table.insert(securities,security)
                      end
                    end
                  end) --pcall
                  bugReport(status,err,v)
                end
              end)--pcall
              bugReport(status,err,v)
            end
          end) --pcall
          bugReport(status,err,v)
        end
      end) --pcall
      bugReport(status,err,v)
    end
  end) --pcall
  bugReport(status,err,v)
  return {securities=securities}
end

function bugReport(status,err,v)
  if not status and reportOnce then
    reportOnce=false
    print (string.rep('#',25).." 8< please report this bug = '"..err.."' >8 "..string.rep('#',25))
    tprint(v)
    print (string.rep('#',25).." 8< please report this bug version="..Version.." >8 "..string.rep('#',25))
  end
end

function EndSession ()
  -- Logout.
  connectWithCSRF("GET","services/participant/logout")
end

-- Download account statements from the EquatePlus document library.
-- This is intentionally independent of the portfolio parsing in RefreshAccount.
function FetchStatements (accounts, knownIdentifiers)
  local statements = {}
  knownIdentifiers = knownIdentifiers or {}

  local libraryContent = connectWithCSRF("POST", "services/documents/library",
    "{\"$type\":\"Object\"}", "application/json;charset=UTF-8")
  if string.find(libraryContent or "", 'id="loginForm"', 1, true) or
     string.find(libraryContent or "", 'id="eqUserId"', 1, true) then
    print("EquatePlus: FetchStatements — session expired, got login page.")
    return {statements=statements}
  end

  local ok, library = pcall(function() return JSON(libraryContent):dictionary() end)
  if not ok or not library or type(library["documents"]) ~= "table" then
    print("EquatePlus: documents/library has no 'documents' field — API may have changed.")
    return {statements=statements}
  end

  for _, document in pairs(library["documents"]) do
    if document["id"] and not knownIdentifiers[document["id"]] then
      local creationDate
      if document["date"] then
        local year, month, day = document["date"]:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
        if year then creationDate = os.time({year=year, month=month, day=day}) end
      end
      local name = document["description"] or "EquatePlus statement"
      local filename = name
      if creationDate then filename = name .. " (" .. MM.localizeDate(creationDate) .. ")" end
      filename = filename:gsub("[/\\\\]", "-") .. ".pdf"

      local statement = {
        name=name,
        identifier=document["id"],
        creationDate=creationDate,
        filename=filename
      }
      statement.pdf = connectWithCSRF("GET", "services/statements/download?documentId=" ..
        urlEncode(document["id"]) .. "&downloadType=inline&source=LIBRARY")
      if statement.pdf and statement.pdf ~= "" and
         not string.find(statement.pdf, '"$type":"TechnicalError"', 1, true) then
        table.insert(statements, statement)
      else
        print("EquatePlus: error downloading statement " .. filename)
      end
    end
  end
  return {statements=statements}
end

-- SE Edition: Debug help - Thanks to https://gist.github.com/ripter/4270799
-- function dump(o)
--    if type(o) == 'table' then
--       local s = '{ '
--       for k,v in pairs(o) do
--         if type(k) ~= 'number' then k = '"'..k..'"' end
--         s = s .. '['..k..'] = ' .. dump(v) .. ','
--       end
--       return s .. '} '
--    else
--      return tostring(o)
--    end
-- end
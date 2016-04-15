param(
    [Parameter(ValueFromPipeline)]
    [string]$JSON,
    [ValidateSet(
		,"2spaces"    ## 2 spaces per indent level</option>
		,"3spaces"    ## 3 spaces per indent level</option>
		,"4spaces"    ## 4 spaces per indent level</option>
		,"compact"    ## Compact (1 line)</option>
		,"javascript" ## JavaScript escaped</option>
		,"tabs"       ## Tab delimited</option>
    )]
    [string]$Indent="2spaces"
)

$webResponse = Invoke-WebRequest -Uri http://www.freeformatter.com/json-formatter.html -Method Post -ContentType "multipart/form-data; boundary=----WebKitFormBoundaryaofIeSAlwrwSAAVy" `
  -Body @"
------WebKitFormBoundaryaofIeSAlwrwSAAVy
Content-Disposition: form-data; name="inputString"

$JSON
------WebKitFormBoundaryaofIeSAlwrwSAAVy
Content-Disposition: form-data; name="inputUrl"

http://www.example.com/myfile.json
------WebKitFormBoundaryaofIeSAlwrwSAAVy
Content-Disposition: form-data; name="indent"

$Indent
------WebKitFormBoundaryaofIeSAlwrwSAAVy
Content-Disposition: form-data; name="forceNewWindow"

true
------WebKitFormBoundaryaofIeSAlwrwSAAVy--
"@

$webResponse.Content

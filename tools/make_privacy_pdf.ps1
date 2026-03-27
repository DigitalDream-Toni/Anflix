$out = 'C:\Users\colli\Documents\Anflix\privacy.pdf'

function Esc([string]$s) {
  $s = $s -replace '\\', '\\\\'
  $s = $s -replace '\(', '\\('
  $s = $s -replace '\)', '\\)'
  return $s
}

function Make-Page($title, $lines) {
  $content = @()
  $content += '0.09 0.45 0.82 rg'
  $content += '0 760 612 32 re f'
  $content += '0 0 0 rg'
  $content += 'BT'
  $content += '/F1 18 Tf'
  $content += '72 770 Td'
  $content += '(' + (Esc $title) + ') Tj'
  $content += '/F1 11 Tf'
  $y = 730
  foreach ($line in $lines) {
    $content += '72 ' + $y + ' Td'
    $content += '(' + (Esc $line) + ') Tj'
    $y -= 16
    if ($y -lt 80) { break }
  }
  $content += 'ET'
  return ($content -join "`n")
}

$pages = @(
  @('Privacy Notice', @(
    'Effective Date: 2026-03-27',
    'This Privacy Notice explains how the Anflix demo site handles information.',
    'This is a non-commercial demonstration project and not a payment platform.',
    'If you do not agree with this Notice, do not use the site.',
    '',
    '1. Scope',
    'This Notice applies to the Anflix demo website and associated pages.',
    'It does not apply to third-party services you may access through links.',
    '',
    '2. Information We Collect',
    'We do not intentionally collect sensitive personal data.',
    'If you contact us, we may receive your email address and message content.',
    'Any information you provide is used only to respond to your inquiry.',
    '',
    '3. Device and Usage Data',
    'This demo site does not deploy analytics trackers or advertising cookies.',
    'Basic server logs may record IP address, browser type, and timestamps.',
    'Such logs are used for security and performance monitoring only.',
    '',
    '4. Cookies',
    'We do not set marketing cookies.',
    'If embedded third-party services are added later, they may set cookies.'
  )),
  @('Privacy Notice (continued)', @(
    '5. Use of Information',
    'Information is used solely for support and communication.',
    'We do not sell, rent, or share personal data with third parties.',
    '',
    '6. Legal Bases (where applicable)',
    'We process data based on legitimate interests in responding to inquiries.',
    'If consent is required, we will request it before processing.',
    '',
    '7. Data Retention',
    'We retain contact messages only as long as necessary to respond and support.',
    'We may retain minimal logs for a reasonable period for security purposes.',
    '',
    '8. Data Security',
    'We take reasonable measures to protect information provided to us.',
    'However, no system is completely secure; you share information at your own risk.',
    '',
    '9. Content and Licensing',
    'Only upload or share content you own or are licensed to use.',
    'We do not claim ownership of user-provided content.',
    '',
    '10. International Transfers',
    'If data is processed across borders, appropriate safeguards will be applied.'
  )),
  @('Privacy Notice (continued)', @(
    '11. Children',
    'This site is intended for general audiences and is not directed to children.',
    'We do not knowingly collect information from children.',
    '',
    '12. Your Rights',
    'Depending on your location, you may have rights to access or delete data.',
    'To exercise these rights, contact us using the details below.',
    '',
    '13. Third-Party Links',
    'Links to other sites are provided for convenience.',
    'We are not responsible for the privacy practices of third-party sites.',
    '',
    '14. Changes to This Notice',
    'We may update this Notice to reflect changes in the demo or legal requirements.',
    'The effective date above will be updated when changes are made.',
    '',
    '15. Contact',
    'For questions about this Notice, contact: privacy@anflix.com.',
    'For general support, contact: support@anflix.com.'
  ))
)

$objects = New-Object System.Collections.Generic.List[string]
$null = $objects.Add($null) # 1 Catalog
$null = $objects.Add($null) # 2 Pages

$contentIds = @()
foreach ($p in $pages) {
  $content = Make-Page $p[0] $p[1]
  $len = [Text.Encoding]::UTF8.GetByteCount($content)
  $obj = '<< /Length ' + $len + ' >>' + "`n" + 'stream' + "`n" + $content + "`n" + 'endstream'
  $null = $objects.Add($obj)
  $contentIds += $objects.Count
}

$pageIds = @()
$fontId = 2 + $pages.Count + $pages.Count + 1
foreach ($cid in $contentIds) {
  $pageObj = '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents ' + $cid + ' 0 R /Resources << /Font << /F1 ' + $fontId + ' 0 R >> >> >>'
  $null = $objects.Add($pageObj)
  $pageIds += $objects.Count
}

$null = $objects.Add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')

$kids = '[' + (($pageIds | ForEach-Object { $_.ToString() + ' 0 R' }) -join ' ') + ']'
$objects[1] = '<< /Type /Pages /Kids ' + $kids + ' /Count ' + $pageIds.Count + ' >>'
$objects[0] = '<< /Type /Catalog /Pages 2 0 R >>'

$pdf = "%PDF-1.4`n"
$offsets = @(0)
for ($i = 0; $i -lt $objects.Count; $i++) {
  $offsets += $pdf.Length
  $pdf += ($i + 1).ToString() + ' 0 obj' + "`n" + $objects[$i] + "`nendobj`n"
}

$xrefOffset = $pdf.Length
$pdf += 'xref' + "`n" + '0 ' + ($objects.Count + 1) + "`n"
$pdf += '0000000000 65535 f ' + "`n"
for ($i = 1; $i -lt $offsets.Count; $i++) {
  $pdf += ('{0:0000000000} 00000 n ' -f $offsets[$i]) + "`n"
}
$pdf += 'trailer' + "`n" + '<< /Size ' + ($objects.Count + 1) + ' /Root 1 0 R >>' + "`n"
$pdf += 'startxref' + "`n" + $xrefOffset + "`n%%EOF`n"

[IO.File]::WriteAllBytes($out, [Text.Encoding]::GetEncoding(28591).GetBytes($pdf))

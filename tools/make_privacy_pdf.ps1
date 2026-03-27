$out = 'C:\Users\colli\Documents\Anflix\privacy.pdf'

function Esc([string]$s) {
  $s = $s -replace '\\', '\\\\'
  $s = $s -replace '\(', '\\('
  $s = $s -replace '\)', '\\)'
  return $s
}

function Make-Page($title, $lines) {
  $content = @()
  # Background and border
  $content += '1 1 1 rg'
  $content += '0 0 612 792 re f'
  $content += '0.12 0.12 0.12 RG'
  $content += '40 40 532 712 re S'

  # Watermark
  $content += '0.85 g'
  $content += 'BT'
  $content += '/F1 48 Tf'
  $content += '140 400 Td'
  $content += '(ANFLIX) Tj'
  $content += 'ET'

  $content += '0.09 0.45 0.82 rg'
  $content += '0 760 612 32 re f'
  $content += '0 0 0 rg'
  $content += 'BT'
  $content += '/F1 18 Tf'
  $content += '72 770 Td'
  $content += '(' + (Esc $title) + ') Tj'
  $content += '/F1 11 Tf'
  $content += '0 -22 Td'
  $content += '(Effective Date: 2026-03-27) Tj'
  $content += 'ET'

  # Header divider
  $content += '0.09 0.45 0.82 RG'
  $content += '72 744 m 540 744 l S'

  # Body
  $content += '0 0 0 rg'
  $content += 'BT'
  $content += '/F1 11 Tf'
  $content += '0 -20 Td'
  $content += '16 TL'
  $content += '0 -10 Td'
  $y = 0
  foreach ($line in $lines) {
    $content += '(' + (Esc $line) + ') Tj'
    $content += 'T*'
    $y += 1
    if ($y -gt 32) { break }
  }
  $content += 'ET'
  return ($content -join "`n")
}

$pages = @(
  @('Privacy Notice', @(
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
    '3. Cookies and Analytics',
    'We do not use advertising cookies or analytics trackers.',
    'If third-party services are added later, they may set their own cookies.',
    '',
    '4. Use of Information',
    'Information is used solely for support and communication.',
    'We do not sell, rent, or share personal data with third parties.',
    '',
    '5. Data Retention and Security',
    'We retain contact messages only as long as necessary to respond and support.',
    'We take reasonable measures to protect information provided to us.',
    'However, no system is completely secure; you share information at your own risk.',
    '',
    '6. Children',
    'This site is not directed to children and we do not knowingly collect their data.',
    '',
    '7. Changes and Contact',
    'We may update this Notice; the effective date will be revised accordingly.',
    'For questions, contact: privacy@anflix.com.'
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

# Function to log messages with timestamp
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $Message"
}

# Executable part
# Load configuration from JSON file
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configFilePath = Join-Path -Path $scriptDirectory -ChildPath "config.json"

if (-not (Test-Path $configFilePath)) {
    Log-Message "Configuration file not found at path: $configFilePath. Script will terminate."
    exit 1
}

$config = Get-Content -Path $configFilePath | ConvertFrom-Json

# Assign parameters from the JSON file
$smtpServer = $config.SMTPServer
$smtpPort = [int]$config.SMTPPort
$from = $config.From
$to = $config.To
$subjectRaw = $config.Subject
$bodyRaw = $config.Body
$username = $config.Username
$password = $config.Password
$useCredentials = [bool]$config.UseCredentials
$attachmentFileName = $config.AttachmentFileName

# Construct the full path for the attachment
$attachment = Join-Path -Path $scriptDirectory -ChildPath $attachmentFileName

# Prepare email subject and body with UTF-8 encoding
$subject = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($subjectRaw))
$body = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($bodyRaw))

# Check if attachment exists
if (-not (Test-Path $attachment)) {
    Log-Message "Attachment not found at path: $attachment. Email will not be sent."
    exit 1
}

# Create MailMessage object
$message = New-Object System.Net.Mail.MailMessage
$message.From = $from
$message.To.Add($to)
$message.Subject = $subject
$message.Body = $body
$message.IsBodyHtml = $false

# Try to attach the file
try {
    Log-Message "Attachment found. Adding to email."
    $attachmentObject = New-Object System.Net.Mail.Attachment -ArgumentList $attachment
    $message.Attachments.Add($attachmentObject)
} catch {
    Log-Message "Error adding attachment: $_"
    $message.Dispose()
    exit 1
}

# Create SMTP client
$smtpClient = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtpClient.EnableSsl = $false # Set to $true if the server requires SSL
$smtpClient.Timeout = 300000  # Set timeout to 300 seconds (5 minutes)

# Conditionally set credentials
if ($useCredentials) {
    Log-Message "Using credentials for authentication."
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
} else {
    Log-Message "No credentials will be used for authentication."
}

# Send the email
try {
    $smtpClient.Send($message)
    Log-Message "Email sent successfully."
} catch {
    Log-Message "Error sending email: $_"
    exit 1
}

# Clean up
$message.Dispose()

if ($attachmentObject -ne $null) {
    $attachmentObject.Dispose()
}
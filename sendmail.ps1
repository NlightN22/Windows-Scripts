# Define parameters
$smtpServer = "your-server.com" # Specify the SMTP server address
$smtpPort = 25                      # Specify the SMTP port (usually 25 or 587)
$from = "username@your-server.com"   # Sender's email address
$to = "test@your-server.com"         # Recipient's email address
$subjectRaw = "Test mail"          # Raw subject text
$bodyRaw = "Test mail"             # Raw body text
$username = "username@your-server.com"
$password = "testpass"
$useCredentials = $false            # Set to $true to enable credentials, $false to disable
$attachmentFileName = "test-attachment.xls" # Relative file name for attachment

# Function to log messages with timestamp
function Log-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $Message"
}

# Executable part
# Determine the script directory and construct the full path for the attachment
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$attachment = Join-Path -Path $scriptDirectory -ChildPath $attachmentFileName

# Prepare email subject and body with UTF-8 encoding
$subject = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($subjectRaw))
$body = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($bodyRaw))

# Check if attachment exists
if (-not (Test-Path $attachment)) {
    Log-Message "Attachment not found at path: $attachment. Email will not be sent."
    exit 1 # Exit the script with an error code
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
    exit 1 # Exit the script with an error code
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
    exit 1 # Exit the script with an error code
}

# Clean up
$message.Dispose()

if ($attachmentObject -ne $null) {
    $attachmentObject.Dispose()
}

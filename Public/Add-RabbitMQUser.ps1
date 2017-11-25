<#
.Synopsis
   Adds user to RabbitMQ server.

.DESCRIPTION
   The Add-RabbitMQUser cmdlet allows to create new users in RabbitMQ server.

   To add a user to remote server you need to provide -HostName.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Add-RabbitMQUser -Name Admin -NewPassword p4ssw0rd -Tag administrator

   Create new user with name Admin having administrator tags set. User is added to local RabbitMQ server.

.EXAMPLE
   Add-RabbitMQUser -HostName rabbitmq.server.com Admin p4ssw0rd administrator

   Create new user with name "Admin", password "p4ssw0rd" having "administrator" tags set. User is added to rabbitmq.server.com server. This command uses positional parameters.
   Note that password for new user is specified as -NewPassword parameter and not -Password parameter, which is used for authorisation to the server.

.INPUTS
   You can pipe Name, NewPassword, Tags and HostName to this cmdlet.

.LINK
    https://www.rabbitmq.com/management.html - information about RabbitMQ management plugin.
#>
function Add-RabbitMQUser
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Low")]
    Param
    (
        # Name of user to create.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string]$Name,

        # Password for new user.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [string]$NewPassword,

        # Comma-separated list of user tags.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [ValidateSet("administrator", "monitoring", "policymaker", "management","impersonator","none")]
        [string[]]$Tag,

        # Name of the computer hosting RabbitMQ server. Defalut value is localhost.
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("HostName", "hn", "cn")]
        [string]$BaseUri = $defaultComputerName,

        # Credentials to use when logging to RabbitMQ server.
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credentials = $defaultCredentials
    )

    Begin
    {
        $cnt = 0
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("server: $BaseUri", "Add user $Name with tag: $Tag"))
        {
            $url = Join-Parts $BaseUri "/api/users/$([System.Web.HttpUtility]::UrlEncode($Name))"
            $body = @{
                'password' = $NewPassword
                'tags' = $Tag -join ','
            } | ConvertTo-Json
            $result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive -ErrorAction Continue -Method Put -ContentType "application/json" -Body $body

            Write-Verbose "Created user $User with tags $Tag"
            $cnt++
        }
    }
    End
    {
        if ($cnt -gt 1) { Write-Verbose "Created $cnt new users." }
    }
}

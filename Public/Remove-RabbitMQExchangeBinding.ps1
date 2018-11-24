<#
.Synopsis
   Removes binding between two RabbitMQ Exchanges.

.DESCRIPTION
   The Remove-RabbitMQExchangeBinding allows for removing bindings between two RabbitMQ exchanges. This cmdlet is marked with High impact.

   To remove Exchange binding from remote server you need to provide -HostName.

   You may pipe an object with names and, optionally, with computer names to remove multiple Exchange bindings. For more information how to do that see Examples.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Remove-RabbitMQExchangeBinding vh1 e1 e2 'e1-e2'

   This command removes binding "e1-e2" between the source exchange named "e1" and destination exchange named "e2". The operation is performed on local server in virtual host vh1.

.EXAMPLE
   Remove-RabbitMQExchangeBinding vh1 e1 e2 'e1-e2' 127.0.0.1

   This command removes binding "e1-e2" between the source exchange named "e1" and destination exchange named "e2". The operation is performed on server 127.0.0.1 in default virtual host (/).

.EXAMPLE
   Remove-RabbitMQExchangeBinding -HostName 127.0.0.0 -VirtualHost vh1 -ExchangeName e1 -Name e2 -RoutingKey 'e1-e2'

   This command removes binding "e1-e2" between the source exchange named "e1" and destination exchange named "e2". The operation is performed on server 127.0.0.1 in default virtual host (/).

.EXAMPLE

.INPUTS

.LINK
    https://www.rabbitmq.com/management.html - information about RabbitMQ management plugin.
#>
function Remove-RabbitMQExchangeBinding
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    Param
    (
        # Name of RabbitMQ Virtual Host.
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName=$true, Position = 0)]
        [Alias("vh", "vhost")]
        [string]$VirtualHost = $defaultVirtualhost,

        # Name of RabbitMQ Source Exchange.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [Alias("exchange", "source")]
        [string]$ExchangeName,

        # Name of RabbitMQ Destination Exchange.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [Alias("targetexchange", "TargetExchangeName", "destination")]
        [string]$Name,

        # Routing key.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=3)]
        [Alias("rk")]
        [string]$RoutingKey,

        # Name of the computer hosting RabbitMQ server. Defalut value is localhost.
        [parameter(ValueFromPipelineByPropertyName=$true, Position=4)]
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
        if ($pscmdlet.ShouldProcess("$BaseUri/$VirtualHost", "Remove binding between source exchange $ExchangeName and destination exchange $Name"))
        {
            $url = Join-Parts $BaseUri "/api/bindings/$([System.Web.HttpUtility]::UrlEncode($VirtualHost))/e/$([System.Web.HttpUtility]::UrlEncode($ExchangeName))/e/$([System.Web.HttpUtility]::UrlEncode($Name))/$([System.Web.HttpUtility]::UrlEncode($RoutingKey))"
            Write-Verbose "Invoking REST API: $url"
        
            $result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive:$InvokeRestMethodKeepAlive -ErrorAction Continue -Method Delete

            Write-Verbose "Removed binding between source exchange $ExchangeName and destination exchange $Name $n on $BaseUri/$VirtualHost"
            $cnt++
        }
    }
    End
    {
        if ($cnt -gt 1) { Write-Verbose "Unbound $cnt Exchanges." }
    }
}

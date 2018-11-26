<#
.Synopsis
   Purges all messages from RabbitMQ Queue.

.DESCRIPTION
    The Clear-RabbitMQQueue removes all messages from given RabbitMQ queue.

   To remove message from Queue on remote server you need to provide -HostName.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Clear-RabbitMQQueue vh1 q1

   Removes all messages from queue "q1" in Virtual Host "vh1" on local computer.

.EXAMPLE
   Clear-RabbitMQQueue -VirtualHost vh1 -Name q1

   Removes all messages from queue "q1" in Virtual Host "vh1" on local computer.

.EXAMPLE
   Clear-RabbitMQQueue -VirtualHost vh1 -Name q1 -HostName rabbitmq.server.com

   Removes all messages from queue "q1" in Virtual Host "vh1" on "rabbitmq.server.com" server.
#>
function Clear-RabbitMQQueue
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    Param
    (
        # Name of RabbitMQ Virtual Host.
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=0)]
        [Alias("vh", "vhost")]
        [string]$VirtualHost = $defaultVirtualHost,

        # The name of the queue from which to receive messages
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [Alias("qn", "QueueName")]
        [string]$Name,
        
        # Name of the computer hosting RabbitMQ server. Defalut value is localhost.
        [parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
        [Alias("cn", "HostName")]
        [string]$BaseUri = $defaultComputerName,

        # Credentials to use when logging to RabbitMQ server.
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credentials = $defaultCredentials
    )

    Begin
    {
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("server: $BaseUri/$VirtualHost", "purge queue $Name"))
        {
            $url = Join-Parts $BaseUri "/api/queues/$([System.Web.HttpUtility]::UrlEncode($VirtualHost))/$([System.Uri]::EscapeDataString($Name))/contents"
            Write-Verbose "Invoking REST API: $url"

            $result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive:$InvokeRestMethodKeepAlive -ErrorAction Continue -Method Delete
        }
    }
    End
    {
    }
}

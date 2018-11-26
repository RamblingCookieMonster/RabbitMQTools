<#
.Synopsis
   Removes Queue from RabbitMQ server.

.DESCRIPTION
   The Remove-RabbitMQQueue allows for removing queues in given RabbitMQ server. This cmdlet is marked with High impact.

   To remove Queue from remote server you need to provide -HostName.

   You may pipe an object with names and, optionally, with computer names to remove multiple Queues. For more information how to do that see Examples.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Remove-RabbitMQQueue q1 -VirtualHost vh1

   This command removes Queue named "q1" from virtual host vh1 located in local RabbitMQ server.

.EXAMPLE
   Remove-RabbitMQQueue q1, q2 -VirtualHost vh1

   This command removes Queues named "q1" and "q2" from local RabbitMQ server.

.EXAMPLE
   Remove-RabbitMQQueue test  -VirtualHost vh1 -HostName myrabbitmq.servers.com

   This command removes Queue named "test" from myrabbitmq.servers.com server.

.EXAMPLE
   @("q1", "q2") | Remove-RabbitMQQueue -VirtualHost vh1

   This command pipes list of Queues to be removed from the RabbitMQ server. In the above example two Queues named "q1" and "q2" will be removed from local RabbitMQ server.

.EXAMPLE
    $a = $(
        New-Object -TypeName psobject -Prop @{"HostName" = "localhost"; "Name" = "e1"}
        New-Object -TypeName psobject -Prop @{"HostName" = "localhost"; "Name" = "e2"}
        New-Object -TypeName psobject -Prop @{"HostName" = "127.0.0.1"; "Name" = "e3"}
    )


   $a | Remove-RabbitMQQueue

   Above example shows how to pipe both Exchange name and Computer Name to specify server from which the Exchange should be removed.
   
   In the above example two Exchanges named "e1" and "e2" will be removed from RabbitMQ local server, and one Exchange named "e3" will be removed from the server 127.0.0.1.

.INPUTS
   You can pipe Exchange names and optionally HostNames to this cmdlet.

.LINK
    https://www.rabbitmq.com/management.html - information about RabbitMQ management plugin.
#>
function Remove-RabbitMQQueue
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    Param
    (
        # Name of RabbitMQ Queue.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [Alias("queue", "QueueName")]
        [string[]]$Name,

        # Name of RabbitMQ Virtual Host.
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("vh", "vhost")]
        [string]$VirtualHost = $defaultVirtualhost,

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
        if ($pscmdlet.ShouldProcess("server: $BaseUri, vhost: $VirtualHost", "Remove queue(s): $(NamesToString $Name '(all)')"))
        {
            foreach($n in $Name)
            {
                $url = Join-Parts $BaseUri "/api/queues/$([System.Web.HttpUtility]::UrlEncode($VirtualHost))/$([System.Uri]::EscapeDataString($n))"
                Write-Verbose "Invoking REST API: $url"
        
                $result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive:$InvokeRestMethodKeepAlive -ErrorAction Continue -Method Delete

                Write-Verbose "Deleted Queue $n on server $BaseUri, Virtual Host $VirtualHost"
                $cnt++
            }
        }
    }
    End
    {
        if ($cnt -gt 1) { Write-Verbose "Deleted $cnt Queue(s)." }
    }
}

<#
.Synopsis
   Adds Queue to RabbitMQ server.

.DESCRIPTION
   The Add-RabbitMQQueue allows for creating new queues in RabbitMQ server.

   To add Queue to remote server you need to provide -HostName.

   You may pipe an object with Name, Queue parameters, VirtualHost and HostName to create multiple queues. For more information how to do that see Examples.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Add-RabbitMQQueue queue1

   This command adds new Queue named "queue1" to local RabbitMQ server.

.EXAMPLE
   Add-RabbitMQQueue queue1, queue2

   This command adds two new queues named "queue1" and "queue2" to local RabbitMQ server.

.EXAMPLE
   Add-RabbitMQQueue queue1 -HostName myrabbitmq.servers.com

   This command adds new queue named "queue1" to myrabbitmq.servers.com server.

.EXAMPLE
   @("queue1", "queue2") | Add-RabbitMQQueue

   This command pipes list of Queues to add to the RabbitMQ server. In the above example two new queues named "queue1" and "queue2" will be created in local RabbitMQ server.

.EXAMPLE
    $a = $(
        New-Object -TypeName psobject -Prop @{"HostName" = "localhost"; "Name" = "vh1"}
        New-Object -TypeName psobject -Prop @{"HostName" = "localhost"; "Name" = "vh2"}
        New-Object -TypeName psobject -Prop @{"HostName" = "127.0.0.1"; "Name" = "vh3"}
    )


   $a | Add-RabbitMQQueue

   Above example shows how to pipe queue definitions to Add-RabbitMQQueue cmdlet.

.EXAMPLE
   Add-RabbitMQQueue -Name 'queue-with-ttl' -Arguments @{'x-message-ttl' = 60000}

   This command will create a new queue and set message TTL to 60 seconds.

.INPUTS
   You can pipe VirtualHost names and optionally HostNames to this cmdlet.

.LINK
    https://www.rabbitmq.com/management.html - information about RabbitMQ management plugin.
#>
function Add-RabbitMQQueue
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Low")]
    Param
    (
        # Name of RabbitMQ Queue.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [Alias("queue", "QueueName")]
        [string[]]$Name,

        # Name of the virtual host to filter channels by.
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Alias("vh", "vhost")]
        [string]$VirtualHost = $defaultVirtualhost,

        # Determines whether the queue should be durable.
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [switch]$Durable = $false,
        
        # Determines whether the queue should be deleted automatically after all consumers have finished using it.
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [switch]$AutoDelete = $false,

        # Name of the computer hosting RabbitMQ server. Defalut value is localhost.
        [parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias("HostName", "hn", "cn")]
        [string]$BaseUri = $defaultComputerName,

        # Credentials to use when logging to RabbitMQ server.
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credentials = $defaultCredentials,

        # Optional arguments
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [hashtable]$Arguments
    )

    Begin
    {
        $cnt = 0
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("server: $BaseUri/$VirtualHost", "Add queue(s): $(NamesToString $Name '(all)'); Durable=$Durable, AutoDelete=$AutoDelete"))
        {
            foreach($n in $Name)
            {
                $url = Join-Parts $BaseUri "/api/queues/$([System.Web.HttpUtility]::UrlEncode($VirtualHost))/$([System.Uri]::EscapeDataString($n))"
                Write-Verbose "Invoking REST API: $url"

                $body = @{}
                if ($Durable) { $body.Add("durable", $true) }
                if ($AutoDelete) { $body.Add("auto_delete", $true) }
                if ($Arguments -ne $null -and $Arguments.Count -gt 0) { $body.Add("arguments", $Arguments) }

                $bodyJson = $body | ConvertTo-Json
                $result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive:$InvokeRestMethodKeepAlive -ErrorAction Continue -Method Put -ContentType "application/json" -Body $bodyJson

                Write-Verbose "Created Queue $n on $BaseUri/$VirtualHost"
                $cnt++
            }
        }
    }
    End
    {
        Write-Verbose "Created $cnt Queue(s)."
    }
}

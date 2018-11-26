<#
.Synopsis
   Adds binding between RabbitMQ exchange and exchange.

.DESCRIPTION
   The Add-RabbitMQExchangeBinding binds RabbitMQ exchange with exchange using RoutingKey

   To add ExchangeBinding to remote server you need to provide -HostName.

   The cmdlet is using REST Api provided by RabbitMQ Management Plugin. For more information go to: https://www.rabbitmq.com/management.html

   To support requests using default virtual host (/), the cmdlet will temporarily disable UnEscapeDotsAndSlashes flag on UriParser. For more information check get-help about_UnEsapingDotsAndSlashes.

.EXAMPLE
   Add-RabbitMQExchangeBinding -VirtualHost vh1 -ExchangeName e1 -Name e2 -RoutingKey 'e1-e2'

   This command binds exchange "e1" with exchange "e2" using routing key "e1-e2". The operation is performed on local server in virtual host vh1.

.EXAMPLE
   Add-RabbitMQExchangeBinding -VirtualHost '/' -ExchangeName e1 -Name e2 -RoutingKey 'e1-e2' -BaseUri 127.0.0.1

   This command binds exchange "e1" with exchange "e2" using routing key "e1-e2". The operation is performed on server 127.0.0.1 in default virtual host (/).

.EXAMPLE
   Add-RabbitMQExchangeBinding -VirtualHost '/' -ExchangeName e1 -Name e2 -Headers @{FirstHeaderKey='FirstHeaderValue'; SecondHeaderKey='SecondHeaderValue'} -BaseUri 127.0.0.1

   This command binds exchange "e1" with exchange "e2" using the headers argument @{FirstHeaderKey='FirstHeaderValue'; SecondHeaderKey='SecondHeaderValue'}. The operation is performed on server 127.0.0.1 in default virtual host (/).

.EXAMPLE
   Add-RabbitMQExchangeBinding -VirtualHost '/' -DontEscape -ExchangeName e1 -Name e2 -Headers @{rjms_erlang_selector="{'=',{'ident',<<"HeadersPropertyName">>},<<"PropertyValue">>}."} -BaseUri 127.0.0.1

   This command binds exchange "e1" with exchange "e2" using the headers argument @{rjms_erlang_selector="{'=',{'ident',<<"HeadersPropertyName">>},<<"PropertyValue">>}."}. The operation is performed on server 127.0.0.1 in default virtual host (/).

   The DontEscape option is required for X-JMS-TOPIC exchanges. The above example will filter for messages which have a header key HeadersPropertyName="PropertyValue".

.INPUTS

.LINK
    https://www.rabbitmq.com/management.html - information about RabbitMQ management plugin.
#>
function Add-RabbitMQExchangeBinding
{
    [CmdletBinding(DefaultParameterSetName='RoutingKey', SupportsShouldProcess=$true, ConfirmImpact="Low")]
    Param
    (
        # Name of the virtual host.
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=0)]
        [Alias("vh", "vhost")]
        [string]$VirtualHost = $defaultVirtualhost,

        # Name of RabbitMQ Exchange.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [Alias("exchange", "source")]
        [string]$ExchangeName,

        # Name of RabbitMQ Exchange.
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [Alias("targetexchange", "TargetExchangeName", "destination")]
        [string]$Name,

        # Routing key.
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=3, ParameterSetName='RoutingKey')]
        [Alias("rk", "routing_key")]
        [string]$RoutingKey,

        # Headers hashtable
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=3, ParameterSetName='Headers')]
        [Hashtable]$Headers = @{},

        # Name of the computer hosting RabbitMQ server. Default value is localhost.
        [parameter(ValueFromPipelineByPropertyName=$true, Position=4)]
        [Alias("HostName", "hn", "cn")]
        [string]$BaseUri = $defaultComputerName,
        
  		# Switch to unescape web characters (For x-jms-topic).
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=5)]
        [switch]$DontEscape,

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
        if ($pscmdlet.ShouldProcess("$BaseUri/$VirtualHost", "Add exchange binding from exchange $ExchangeName to exchange $Name with $($PSCmdlet.ParameterSetName)"))
        {
            foreach($n in $Name)
            {
                $url = Join-Parts $BaseUri "/api/bindings/$([System.Web.HttpUtility]::UrlEncode($VirtualHost))/e/$([System.Uri]::EscapeDataString($ExchangeName))/e/$([System.Uri]::EscapeDataString($Name))"
                Write-Verbose "Invoking REST API: $url"

                $body = @{
                    "routing_key" = $RoutingKey
		            "arguments" = $headers
                }

                # Unescape after converting to JSON (for x-jms-topic type)
				if ($DontEscape)
				{
					$bodyJson = $body | ConvertTo-Json -Depth 3 -Compress | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
				}
				else
				{
					$bodyJson = $body | ConvertTo-Json -Depth 3 -Compress
				}
				$result = Invoke-RestMethod $url -Credential $Credentials -AllowEscapedDotsAndSlashes -DisableKeepAlive:$InvokeRestMethodKeepAlive -ErrorAction Continue -Method Post -ContentType "application/json" -Body $bodyJson

                Write-Verbose "Bound exchange $ExchangeName to exchange $Name $n on $BaseUri/$VirtualHost"
                $cnt++
            }
        }
    }
    End
    {
        Write-Verbose "Created $cnt Binding(s)."
    }
}

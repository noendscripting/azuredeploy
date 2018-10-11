
Add-Type -AssemblyName PresentationCore, PresentationFramework
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window" Title="Initial Window" WindowStartupLocation = "CenterScreen"
    Width = "550" Height = "600" ShowInTaskbar = "True">
    <Grid>
        <Label Content="Create Forest Configuration" HorizontalAlignment="Center" Margin="0,1,0,0" Height="43" Width ="550" VerticalAlignment="Top" Background="#FF0067B8" Foreground="White" FontSize="24" HorizontalContentAlignment="Center"/>
        <Label Name="lblForestFQDN" Content="Forest FQDN" HorizontalAlignment="Left" Margin="0,43,0,0" VerticalAlignment="Top" Width="260" Height="30"  Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center" />
        <TextBox HorizontalAlignment="Left" Height="30" Margin="260,43,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="270"  />
        <Label Name="lblForetsLDAP" Content="Forest LDAP" HorizontalAlignment="Left" Margin="0,73,0,0" VerticalAlignment="Top" Width="260" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <TextBox HorizontalAlignment="Left" Height="30" Margin="260,73,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="270"  />
        <Label Name="lblDediccatedExportDC" Content="Dedicated Export DC1" HorizontalAlignment="Left" Margin="0,103,0,0" VerticalAlignment="Top" Width="260" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <TextBox HorizontalAlignment="Left" Height="30" Margin="260,103,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="270"  />
        <Label Name="lblADExportNetBiosName" Content="AD Export Netbios Name" HorizontalAlignment="Left" Margin="0,133,0,0" VerticalAlignment="Top" Width="260" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <TextBox HorizontalAlignment="Left" Height="30" Margin="260,133,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="270"  />
        <Label Name="lblDedicatedDCScanNetbiosName" Content="Dedicated DC Scan Netbios Name" HorizontalAlignment="Left" Margin="0,163,0,0" VerticalAlignment="Top" Width="260" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <TextBox HorizontalAlignment="Left" Height="30" Margin="260,163,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="270"  />
        <Button Content="Update" HorizontalAlignment="Center" Margin="0,200,0,0" VerticalAlignment="Top" Width="75" Foreground="White">
            <Button.Background>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF0067B8" Offset="1"/>
                </LinearGradientBrush>
            </Button.Background>
        </Button>
    </Grid>
</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )
$Window.ShowDialog()
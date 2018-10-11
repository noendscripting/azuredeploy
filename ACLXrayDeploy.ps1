[xml]$XAML  = @" 
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp1"
        
        Title="MainWindow" Height="600" Width="450">
    <Grid>
        <Label Content="Create Forest Configuration" HorizontalAlignment="Center" Margin="0,1,0,0" Height="43" Width ="450" VerticalAlignment="Top" Background="#FF0067B8" Foreground="White" FontSize="24" HorizontalContentAlignment="Center"/>
        <Label Name="lblForestFQDN" Content="Forest FQDN" HorizontalAlignment="Left" Margin="0,43,0,0" VerticalAlignment="Top" Width="125" Height="30"  Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center" />
        <Label Name="lblForetsLDAP" Content="Forest LDAP" HorizontalAlignment="Left" Margin="0,73,0,0" VerticalAlignment="Top" Width="125" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <Label Content="Label" HorizontalAlignment="Left" Margin="0,103,0,0" VerticalAlignment="Top" Width="125" Height="30" Background="#FF0067B8" Foreground="White" BorderBrush="Black" BorderThickness="1" FontSize="16" HorizontalContentAlignment="Center"/>
        <TextBox HorizontalAlignment="Left" Height="30" Margin="125,43,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="205"  />
        <TextBox HorizontalAlignment="Left" Height="30" Margin="125,73,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="205"  />
        <TextBox HorizontalAlignment="Left" Height="30" Margin="125,103,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="205"  />
        <Button Content="Update" HorizontalAlignment="Left" Margin="135,170,0,0" VerticalAlignment="Top" Width="75" Foreground="White">
            <Button.Background>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF0067B8" Offset="1"/>
                </LinearGradientBrush>
            </Button.Background>
        </Button>
        <RichTextBox HorizontalAlignment="Center" Height="390" Margin="10,200,10,10" VerticalAlignment="Top" Width="430" BorderThickness="1" BorderBrush="Black">
            <FlowDocument>
                <Paragraph >
                    <Run Text="RichTextBox"/>
                </Paragraph>
            </FlowDocument>
        </RichTextBox>

    </Grid>


</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader  $xaml)
$Window=[Windows.Markup.XamlReader]::Load(  $reader ) 
$Null = $Window.ShowDialog()

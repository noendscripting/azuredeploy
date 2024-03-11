  
  Param(
[string]$emailAddress,
[string]$groupName

  )
  
  
  
  $outlook = new-object -com Outlook.Application
  $contacts = $outlook.Session.GetDefaultFolder(10)
  $session = $outlook.Session
  $session.Logon("Outlook")
  $namespace = $outlook.GetNamespace("MAPI")
  $recipient = $namespace.CreateRecipient($emailAddress)  # this has to be an exsiting contact
  $recipient.Resolve()  # check if this returns true
  $DL = $contacts.Items($groupName)
  $DL.AddMember($recipient)
  $DL.Save()
  
Strict

Public

' Imports (Public):
Import core
Import packet
Import user

' Imports (Private):
Private

Import brl.socket

Public

' Interfaces:
Interface ClientApplication Extends NetApplication
	' Methods:
	
	' The return-value indicates if 'C' should start receiving messages.
	Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
	
	' This is called when a client is disconnected from a 'Server'.
	Method OnClientDisconnected:Void(C:Client)
End

' Classes:

' This is used to connect to a 'Server'; not to be confused with 'NetHandle'.
Class Client Extends NetworkManager<ClientApplication> Implements IOnConnectComplete ' Final
	' Functions:
	Function GetProtocol:String(Protocol:ProtocolType)
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				Return "stream"
			Case TRANSPORT_PROTOCOL_UDP
				Return "datagram"
		End Select
		
		Return ""
	End
	
	Function GetProtocol:ProtocolType(Protocol:String)
		Select Protocol
			Case "datagram"
				Return TRANSPORT_PROTOCOL_UDP
			Default ' Case "stream"
				Return TRANSPORT_PROTOCOL_TCP
		End Select
	End
	
	' Constructor(s):
	
	' This overload automatically calls 'Begin'.
	Method New(Hostname:String, Port:Int, Parent:ClientApplication, Protocol:ProtocolType=TRANSPORT_PROTOCOL_TCP, PacketSize:Int=Default_PacketSize, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketSize, PacketPoolSize)
		
		Begin(Hostname, Port, Protocol)
	End
	
	' This overload does not call 'Begin'.
	Method New(Parent:ClientApplication, PacketSize:Int=Default_PacketSize, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketSize, PacketPoolSize)
	End
	
	' Destructor(s):
	Method Close:Void()
		Super.Close()
		
		AcceptingMessages = False
	End
	
	' Methods (Public):
	Method Begin:Void(Hostname:String, RemotePort:Int, Protocol:ProtocolType)
		Self.Protocol = Protocol
		
		RawBegin(Hostname, RemotePort, GetProtocol(Protocol))
		
		Return
	End
	
	' This connects to a remote 'Server' using 'Hostname' and 'Port' over 'Protocol'.
	Method Begin:Void(Hostname:String, RemotePort:Int, Protocol:String="stream")
		Self.Protocol = GetProtocol(Protocol)
		
		RawBegin(Hostname, RemotePort, Protocol)
		
		Return
	End
	
	Method AcceptMessages:Bool(Force:Bool=False)
		If (AcceptingMessages And Not Force) Then
			Return False
		Endif
		
		Local Response:= AcceptMessagesWith(Connection)
		
		If (Response) Then
			AcceptingMessages = True
			
			Return True ' AcceptingMessages
		Endif
		
		' Return the default response.
		Return False
	End
	
	Method Accept:Bool(Force:Bool=False)
		Return AcceptMessages(Force)
	End
	
	Method Send:Int(P:Packet)
		Return RawSendPacketTo(Connection, P)
	End
	
	Method SendAsync:Void(P:Packet)
		RawSendPacketToAsync(Connection, P)
		
		Return
	End
	
	' Methods (Protected):
	Protected
	
	Method OnDisconnectMessage:Void(S:Socket) ' Final
		' Notify the user.
		Parent.OnClientDisconnected(Self)
		
		Return
	End
	
	Method RawBegin:Void(Hostname:String, RemotePort:Int, Protocol:String="stream")
		Port = RemotePort
		
		' Allocate a 'Socket' using 'Protocol'.
		Local S:= New Socket(Protocol)
		
		' Attempt to connect to 'Hostname' using 'Port'.
		' If this is successful, 'S' will become 'Connection'.
		S.ConnectAsync(Hostname, RemotePort, Self)
		
		Return
	End
	
	' BRL:
	Method OnConnectComplete:Void(Success:Bool, ClientSocket:Socket)
		Self.Connection = ClientSocket
		
		' Tell our parent what's going on.
		Local Response:= Parent.OnClientBound(Self, Port, Success)
		
		If (Success) Then
			If (Response) Then
				Accept()
			Endif
		Else
			Close()
			
			Return
		Endif
		
		Return
	End
	
	Public
	
	' Fields (Protected):
	Protected
	
	Field AcceptingMessages:Bool = False
	
	Public
End
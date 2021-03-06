using System;
using System.Xml;
using System.Web;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Collections.Generic;
namespace SonicwallParser {
	public class AccessPolicy {
		public int Number;
		public string Comment;
		public string Action;
		public bool Enabled;
		
		public string Source;
		public string SourceZone;
		public string SourceService;
		
		public string Destination;
		public string DestinationZone;
		public string DestinationService;
		
		public double BytesRx;
		public double BytesTx;
    }
	public class FirewallObject {
		public string Name;
		public string Description;
		public string Type;
		public List<string> Members;
		public List<string> Expanded;
    }
	public class NatPolicy {
		public int Index;
		public int Usage;
		public string Comment;
		public bool Enabled;
		public bool BuiltIn;
		
		public string OriginalSource;
		public string TranslatedSource;
		
		public string OriginalDestination;
		public string TranslatedDestination;
		
		public string OriginalService;
		public string TranslatedService;
		
		public string InboundInterface;
		public string OutboundInterface;
    }
}

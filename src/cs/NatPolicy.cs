using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace SonicwallParser {
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
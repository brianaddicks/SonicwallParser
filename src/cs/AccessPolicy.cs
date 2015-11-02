using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace SonicwallParser {
	public class AccessPolicy {
		public int Number;
		public string Name;
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
}
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace SonicwallParser {
	public class FirewallObject {
		public string Name;
		public string Description;
		public List<string> Members;
		public List<string> Expanded;
    }
}
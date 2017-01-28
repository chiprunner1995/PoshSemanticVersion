using System;
using System.Collections.Generic;
//using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
//using System.Threading.Tasks;

namespace SemanticVersionCS
{
    public class SemanticVersion : IComparable
    {
        private Regex preReleaseRegEx = new Regex(@"^(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)$", RegexOptions.Compiled | RegexOptions.IgnoreCase);

        private string[] preRelease;
        private string[] build;

        public uint Major;
        public uint Minor;
        public uint Patch;
        public string[] PreRelease
        {
            get
            {
                return preRelease;
            }
            set
            {
                foreach (string element in value)
                {
                    //Match match = preReleaseRegEx.Match(element);
                    //if (! match.Success)
                    //{
                    //   throw new System.ArgumentException("Invalid PreRelease format.");
                    //}

                    if (!(preReleaseRegEx.IsMatch(element)))
                    {
                        throw new System.ArgumentException(String.Format("Invalid PreRelease identifier \"{0}\".", element));
                    }
                }

                preRelease = value;
            }
        }
        public string[] Build
        {
            get
            {
                return build;
            }
            set
            {
                build = value;
            }
        }

        public SemanticVersion()
        {
            Major = 0;
            Minor = 0;
            Patch = 0;
            PreRelease = new string[] { };
            Build = new string[] { };
        }

        public int CompareTo(object obj)
        {
            return 0;
        }

        // Equals

        // ToString

        public override string ToString()
        {
            //string outputString = Major + "." + Minor + "." + Patch;
            string outputString = String.Format("{0}.{1}.{2}", Major, Minor, Patch);

            if (PreRelease.Length > 0)
            {
                string preReleaseString = String.Format("-{0}", String.Join(".", PreRelease));
                //outputString += preReleaseString;
                outputString = outputString + preReleaseString;
            }

            if (Build.Length > 0)
            {
                string buildString = String.Format("+{0}", String.Join(".", Build));
                outputString += buildString;
            }

            return outputString;
        }
    }
}

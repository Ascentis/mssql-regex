using System;
using System.Globalization;
using System.IO;
using System.Text;

namespace AssemblyAsText
{
    internal class Program
    {
        private static string GetHexString(string assemblyPath)
        {
            if (!Path.IsPathRooted(assemblyPath))
                assemblyPath = Path.Combine(Environment.CurrentDirectory, assemblyPath);

            StringBuilder builder = new StringBuilder();
            builder.Append("0x");

            using (FileStream stream = new FileStream(assemblyPath,
                FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                var currentByte = stream.ReadByte();
                while (currentByte > -1)
                {
                    builder.Append(currentByte.ToString("X2", CultureInfo.InvariantCulture));
                    currentByte = stream.ReadByte();
                }
            }

            return builder.ToString();
        }

        private static void Main(string[] args)
        {
            if (args.Length <= 0)
            {
                Console.WriteLine("Usage: AssemblyAsText <fileName>");
                return;
            }
                
            Console.Write(GetHexString(args[0]));
        }
    }
}

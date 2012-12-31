using System;

namespace MrCoffee {
    class App {
        static void Main(string[] args) {
            string path = @"C:\Program Files\Java\jdk1.7.0_01";
            Environment.SetEnvironmentVariable("JAVA_HOME", path);
            System.Console.WriteLine("JAVA_HOME has been set to {0}", path);
        }
    }
}

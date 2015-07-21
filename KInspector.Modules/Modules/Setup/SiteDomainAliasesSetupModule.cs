﻿using System;
using KInspector.Core;

namespace KInspector.Modules.Modules.Setup
{
    public class SiteDomainAliasesSetupModule : IModule
    {
        public ModuleMetadata GetModuleMetadata()
        {
            return new ModuleMetadata
            {
                Name = "Assign all sites domain alias 'localhost'",
                Comment = "Assigns domain alias 'localhost' to all sites (deletes existing 'localhost' domain aliases).",
                SupportedVersions = new[] { 
                    new Version("8.0"), 
                    new Version("8.1"), 
                    new Version("8.2") 
                },
                Category = "Setup",
            };
        }

        public ModuleResults GetResults(InstanceInfo instanceInfo, DatabaseService dbService)
        {
            var results = dbService.ExecuteAndGetPrintsFromFile("Setup/SiteDomainAliasesSetupModule.sql");

            return new ModuleResults
            {
                Result = results
            };
        }
    }
}
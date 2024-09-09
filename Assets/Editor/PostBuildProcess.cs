using UnityEditor;
using UnityEngine;
using UnityEditor.Callbacks;
using System.IO;

public class PostBuildProcess {
    [PostProcessBuild]
    public static void OnPostprocessBuild(BuildTarget target, string pathToBuiltProject) {
        // 构建后的文件夹路径
        string buildFolder = Path.GetDirectoryName(pathToBuiltProject);

        // 要复制的源文件夹
        string sourceFolder = Path.Combine(Application.dataPath, "Configs");

        // 目标路径（构建后的根目录）
        string destinationFolder = Path.Combine(buildFolder, "Configs");

        CopyDirectory(sourceFolder, destinationFolder);

    }


    private static void CopyFile(string sourceFile, string destinationFile){
        if (sourceFile.EndsWith(".meta")) 
            return;
        string destinationDir = Path.GetDirectoryName(destinationFile);

        if (!Directory.Exists(destinationDir)){
            Directory.CreateDirectory(destinationDir);
        }

        File.Copy(sourceFile, destinationFile, true);
    }

    private static void CopyDirectory(string sourceDir, string destinationDir){
        if (!Directory.Exists(destinationDir)){
            Directory.CreateDirectory(destinationDir);
        }

        foreach (string file in Directory.GetFiles(sourceDir)){
            string destinationFile = Path.Combine(destinationDir, Path.GetFileName(file));
            CopyFile(file, destinationFile);
        }

        foreach (string dir in Directory.GetDirectories(sourceDir)){
            string destinationSubDir = Path.Combine(destinationDir, Path.GetFileName(dir));
            CopyDirectory(dir, destinationSubDir);
        }
    }
}

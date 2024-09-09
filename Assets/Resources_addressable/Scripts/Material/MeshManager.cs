using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct MeshInfo{
    public string name;
    public string path;
}

public struct MeshesInfo{
    public string version;
    public Dictionary<string, MeshInfo> meshes;
}

public class MeshManager: BaseClass{
    public MeshesInfo _meshes_info;
    public Dictionary<string, AsyncOperationHandle<Mesh>> _name2mesh = new();

    public MeshManager(){
        load_materials();
    }

    public bool _check_info_initDone(){
        return !(_meshes_info.version == null);
    }

    public bool _check_exist(string name){
        return _meshes_info.meshes.ContainsKey(name);
    }

    public bool _check_loaded(string name){
        return _name2mesh.ContainsKey(name);
    }

    public Mesh _get_mesh(string name){
        return _name2mesh[name].Result;
    }

    async UniTaskVoid load_mesh(string name){
        string mesh_path = _meshes_info.meshes[name].path;
        AsyncOperationHandle<Mesh> handle = Addressables.LoadAssetAsync<Mesh>(mesh_path);
        handle.Completed += action_mesh_loaded;
        await UniTask.Yield();
    }

    void load_materials(){
        string jsonText = File.ReadAllText(_GCfg.__MeshesInfo_path);
        _meshes_info = JsonConvert.DeserializeObject<MeshesInfo>(jsonText);
        foreach (var object_kv in _meshes_info.meshes){
            load_mesh(object_kv.Key).Forget();
        }
    }

    void action_mesh_loaded(AsyncOperationHandle<Mesh> handle){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2mesh.Add(handle.Result.name, handle);
        else Debug.LogError("Failed to load material: " + handle.DebugName);
        // Addressables.Release(handle);
    }
}

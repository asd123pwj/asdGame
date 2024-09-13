using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct MeshInfo{
    public string path;
}

public struct MeshesInfo{
    public string version;
    public Dictionary<string, MeshInfo> items;
}

public class MeshManager: BaseClass{
    public MeshesInfo _infos;
    public Dictionary<string, AsyncOperationHandle<Mesh>> _ID2mesh = new();

    public MeshManager(){
        load_materials();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _ID2mesh.ContainsKey(ID);
    }

    public Mesh _get_mesh(string ID){
        return _ID2mesh[ID].Result;
    }

    void load_item(string ID){
        string mesh_path = _infos.items[ID].path;
        AsyncOperationHandle<Mesh> handle = Addressables.LoadAssetAsync<Mesh>(mesh_path);
        handle.Completed += (operationHandle) => action_mesh_loaded(operationHandle, ID);
    }

    void load_materials(){
        string jsonText = File.ReadAllText(_GCfg.__MeshesInfo_path);
        _infos = JsonConvert.DeserializeObject<MeshesInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_item(object_kv.Key);
        }
    }

    void action_mesh_loaded(AsyncOperationHandle<Mesh> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _ID2mesh.Add(ID, handle);
        else Debug.LogError("Failed to load material: " + handle.DebugName);
        // Addressables.Release(handle);
    }
}

using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct MaterialInfo{
    public string path;
}

public struct MaterialsInfo{
    public string version;
    public Dictionary<string, MaterialInfo> items;
}

public class MaterialManager: BaseClass{
    public MaterialsInfo _infos;
    public Dictionary<string, AsyncOperationHandle<Material>> _name2material = new();

    public MaterialManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _name2material.ContainsKey(ID);
    }

    public Material _get_mat(string ID){
        return _name2material[ID].Result;
    }

    void load_item(string ID){
        string UIPrefab_path = _infos.items[ID].path;
        AsyncOperationHandle<Material> handle = Addressables.LoadAssetAsync<Material>(UIPrefab_path);
        handle.Completed += (operationHandle) => action_material_loaded(operationHandle, ID);
    }

    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__MaterialsInfo_path);
        _infos = JsonConvert.DeserializeObject<MaterialsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_item(object_kv.Key);
        }
    }

    void action_material_loaded(AsyncOperationHandle<Material> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2material.Add(ID, handle);
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
        // Addressables.Release(handle);
    }
}

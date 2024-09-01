using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct MaterialInfo{
    public string name;
    public string path;
}

public struct MaterialsInfo{
    public string version;
    public Dictionary<string, MaterialInfo> materials;
}

public class MaterialManager: BaseClass{
    public MaterialsInfo _materials_info;
    public Dictionary<string, Material> _name2material = new();

    public MaterialManager(){
        load_materials();
    }

    public bool _check_info_initDone(){
        return !(_materials_info.version == null);
    }

    public bool _check_exist(string name){
        return _materials_info.materials.ContainsKey(name);
    }

    public bool _check_loaded(string name){
        return _name2material.ContainsKey(name);
    }

    public Material _get_mat(string name){
        return _name2material[name];
    }

    async UniTaskVoid load_UIPrefab(string name){
        string UIPrefab_path = _materials_info.materials[name].path;
        AsyncOperationHandle<Material> handle = Addressables.LoadAssetAsync<Material>(UIPrefab_path);
        handle.Completed += action_material_loaded;
        await UniTask.Yield();
    }

    void load_materials(){
        string jsonText = File.ReadAllText(_GCfg.__MaterialsInfo_path);
        _materials_info = JsonConvert.DeserializeObject<MaterialsInfo>(jsonText);
        foreach (var object_kv in _materials_info.materials){
            load_UIPrefab(object_kv.Key).Forget();
        }
    }

    void action_material_loaded(AsyncOperationHandle<Material> handle){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2material.Add(handle.Result.name, handle.Result);
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
        Addressables.Release(handle);
    }
}

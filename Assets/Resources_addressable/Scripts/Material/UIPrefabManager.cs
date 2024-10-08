using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using Unity.VectorGraphics;

public struct UIPrefabInfo{
    public string path;
}

public struct UIPrefabsInfo{
    public string version;
    public Dictionary<string, UIPrefabInfo> items;
}

public class UIPrefabManager: BaseClass{
    // GameConfigs _GCfg;
    public UIPrefabsInfo _infos;
    public Dictionary<string, AsyncOperationHandle<GameObject>> _ID2UIPrefab = new();

    public UIPrefabManager(){
        // _game_configs = game_configs;
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _ID2UIPrefab.ContainsKey(ID);
    }

    public GameObject _get_pfb(string ID){
        return _ID2UIPrefab[ID].Result;
    }

    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__UIPrefabsInfo_path);
        _infos = JsonConvert.DeserializeObject<UIPrefabsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_UIPrefab(object_kv.Key);
        }
    }

    void load_UIPrefab(string ID){
        string UIPrefab_path = _infos.items[ID].path;
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(UIPrefab_path);
        handle.Completed += (operationalHandle) => action_UIPrefab_loaded(operationalHandle, ID);
    }

    void action_UIPrefab_loaded(AsyncOperationHandle<GameObject> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _ID2UIPrefab.Add(ID, handle);
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
        // Addressables.Release(handle);
    }
}

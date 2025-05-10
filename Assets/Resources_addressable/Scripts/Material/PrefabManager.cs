using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;


public struct PrefabsInfo{
    public string version;
    public Dictionary<string, string> items;
}

public class PrefabManager: BaseClass{
    public PrefabsInfo _infos;
    public Dictionary<string, AsyncOperationHandle<GameObject>> _ID2Prefab = new();

    public PrefabManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _ID2Prefab.ContainsKey(ID);
    }

    public GameObject _get_prefab(string ID){
        return _ID2Prefab[ID].Result;
    }

    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__PrefabsInfo_path);
        _infos = JsonConvert.DeserializeObject<PrefabsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_item(object_kv.Key);
        }
    }

    void load_item(string ID){
        string Prefab_path = _infos.items[ID];
        AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(Prefab_path);
        handle.Completed += (operationalHandle) => action_item_loaded(operationalHandle, ID);
    }

    void action_item_loaded(AsyncOperationHandle<GameObject> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _ID2Prefab.Add(ID, handle);
        else Debug.LogError("Failed to load prefab: " + handle.DebugName);
    }
}

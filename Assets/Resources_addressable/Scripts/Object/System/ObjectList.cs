// using System.Collections.Generic;
// using System.IO;
// using Newtonsoft.Json;
// using UnityEngine;
// using UnityEngine.AddressableAssets;
// using UnityEngine.ResourceManagement.AsyncOperations;
// using Cysharp.Threading.Tasks;
// using System;

// // public struct ObjectInfo{
// //     public string ID;
// //     public string name;
// //     public string description;
// //     public string path;
// //     public string path_thumbnail;
// //     public ObjectTags tags;
// // }

// // public struct ObjectsInfo{
// //     public string version;
// //     public Dictionary<string, ObjectInfo> objects;
// // }

// public class ObjectList{
//     GameConfigs _GCfg;
//     public ObjectsInfo _objects_info;
//     public Dictionary<string, GameObject> _name2object = new();
//     public Dictionary<string, string> _ID2objectName = new();

//     public ObjectList(GameConfigs GCfg){
//         _GCfg = GCfg;
//         load_objects();
//     }

//     public GameObject _load_object_by_name(string name){
//         return _name2object[name];
//     }

//     async UniTaskVoid load_object(string name){
//         string object_path = _objects_info.objects[name].path;
//         AsyncOperationHandle<GameObject> handle = Addressables.LoadAssetAsync<GameObject>(object_path);
//         handle.Completed += action_prefab_loaded;
//         await UniTask.Yield();
//     }

//     void load_objects(){
//         // string objects_info_path = _game_configs.__objectsInfo_path;
//         string jsonText = File.ReadAllText(_GCfg.__objectsInfo_path);
//         _objects_info = JsonConvert.DeserializeObject<ObjectsInfo>(jsonText);
//         _ID2objectName.Add("0", "");
//         foreach (var object_kv in _objects_info.objects){
//             _ID2objectName.Add(object_kv.Value.ID, object_kv.Key);
//             load_object(object_kv.Key).Forget();
//         }
//     }

//     void action_prefab_loaded(AsyncOperationHandle<GameObject> handle){
//         // Debug.Log("Loaded prefab: " + handle.Result.name);
//         if (handle.Status == AsyncOperationStatus.Succeeded) _name2object.Add(handle.Result.name, handle.Result);
//         else Debug.LogError("Failed to load prefab: " + handle.DebugName);
//         Addressables.Release(handle);
//     }
// }

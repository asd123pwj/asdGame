using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.EventSystems;
using UnityEditor.UI;
using Cysharp.Threading.Tasks;
using System.Collections.Generic;
using Newtonsoft.Json;


public class UIThumbnail: UIBase{
    public UIThumbnail(GameObject parent, UIInfo info): base(parent, info){
    }


    public override void _init_done(){
        set_background().Forget();
    }

    async UniTaskVoid set_background(){
        Image img = _self.GetComponent<Image>() ?? _self.AddComponent<Image>();
        while (!_MatSys._check_info_initDone()) {
            Debug.Log("waiting for Material System init.");
            await UniTask.Delay(100);
        }
        if (_MatSys._obj._check_exist(_background_key)){
            while (!_MatSys._obj._check_thumbnail_loaded(_background_key)) {
                Debug.Log("waiting for object thumbnail loaded: " + _name + " - " + _background_key);
                await UniTask.Delay(100);
            }
            img.sprite = _MatSys._obj._get_thumbnail(_background_key);
        }
        else{
            Debug.Log("No thumbnail found: " + _name + " - " + _background_key);
        }
    }

    public void _instantiate(Vector2 pos){
        _sys._ObjSys._object_spawn._instantiate(_name, pos);
    }
}

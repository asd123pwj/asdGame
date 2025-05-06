using UnityEngine.EventSystems;

public class UIUpdateSelectedTileByUIName: UIInteractBase{
    public string UIName => _Base._info.name;
    public UIUpdateSelectedTileByUIName(UIBase Base): base(Base){
        _set_trigger(0);
    }

    public override void _PointerDown(BaseEventData eventData, bool isBuildIn=true){
        if (!_isAvailable(eventData)) return;
        _update_selectedTile_by_UIName();
    }
    
    void _update_selectedTile_by_UIName(){
        _Msg._send2COMMAND($"TMapSetSelectedTile --tile_ID \"{UIName}\"");
    }
}

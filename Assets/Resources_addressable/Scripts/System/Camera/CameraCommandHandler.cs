using System.Collections.Generic;


public class CameraCommandHandler: BaseClass{
    public void register(){
        CommandSystem._add(nameof(CamZoom), CamZoom);
    }

    void CamZoom(Dictionary<string, object> args){
        /* CamZoom                  Zoom in/out
         * --[in] (flag)       
         * --[out] (flag)        
         * 
         * Example:
         *   CamZoom --in            Zoom in
         *   CamZoom --out           Zoom out
         */
        _sys._CamMgr._zoom(args.ContainsKey("in"));
    }
    
}
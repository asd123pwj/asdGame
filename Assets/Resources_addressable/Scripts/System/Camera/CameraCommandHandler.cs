using System.Collections.Generic;


public class CameraCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(CamZoom);
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
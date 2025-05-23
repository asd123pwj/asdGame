public class ObjectAsPlayer: ObjectAsBase{
    public ObjectAsPlayer(ObjectBase Base): base(Base){}

    public override void _apply(){
        BaseClass._sys._ObjSys._mon._set_player(_Base);
    }

    public override void _clear(){
        if ( BaseClass._sys._ObjSys._mon._get_player() == _Base){
            BaseClass._sys._ObjSys._mon._set_player(null);
        }
    }
}
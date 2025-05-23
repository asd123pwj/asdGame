public class ObjectAsBase{
    public ObjectBase _Base;
    public ObjectAsBase(ObjectBase Base){
        _Base = Base;
    }

    public virtual void _apply(){}

    public virtual void _clear(){}
}
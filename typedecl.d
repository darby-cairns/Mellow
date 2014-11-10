import std.stdio;
import std.algorithm;
import std.range;

// TODO:
//   The myriad print() functions in the Type definitions should be converted
//   to string format() functions that simply build and return a string for
//   printing.

enum TypeEnum
{
    VOID,
    LONG,
    INT,
    SHORT,
    BYTE,
    FLOAT,
    DOUBLE,
    CHAR,
    BOOL,
    STRING,
    SET,
    HASH,
    ARRAY,
    AGGREGATE,
    TUPLE,
    FUNCPTR,
    STRUCT,
    VARIANT,
}

struct ArrayType
{
    Type* arrayType;

    ArrayType* copy()
    {
        auto c = new ArrayType();
        c.arrayType = this.arrayType.copy;
        return c;
    }

    string format()
    {
        return "[]" ~ arrayType.format();
    }
}

struct HashType
{
    Type* keyType;
    Type* valueType;

    HashType* copy()
    {
        auto c = new HashType();
        c.keyType = this.keyType.copy;
        c.valueType = this.valueType.copy;
        return c;
    }

    string format()
    {
        return "[" ~ keyType.format() ~ "]" ~ valueType.format();
    }
}

struct SetType
{
    Type* setType;

    SetType* copy()
    {
        auto c = new SetType();
        c.setType = this.setType.copy;
        return c;
    }

    string format()
    {
        return "<>" ~ setType.format();
    }
}

struct AggregateType
{
    string typeName;
    Type*[] templateInstantiations;

    AggregateType* copy()
    {
        auto c = new AggregateType();
        c.typeName = this.typeName;
        c.templateInstantiations = this.templateInstantiations
                                       .map!(a => a.copy)
                                       .array;
        return c;
    }

    string format()
    {
        string str = typeName;
        if (templateInstantiations.length == 1)
        {
            str ~= "!" ~ templateInstantiations[0].format();
        }
        else if (templateInstantiations.length > 1)
        {
            str ~= "!(" ~ templateInstantiations.map!(a => a.format())
                                                .join(", ");
            str ~= ")";
        }
        return str;
    }
}

struct TupleType
{
    Type*[] types;

    TupleType* copy()
    {
        auto c = new TupleType();
        c.types = this.types
                      .map!(a => a.copy)
                      .array;
        return c;
    }

    string format()
    {
        return "(" ~ types.map!(a => a.format()).join(", ") ~ ")";
    }
}

// Type representing the value that is a callable function pointer
struct FuncPtrType
{
    // The types of the arguments to the function, in the order they appeared
    // in the original argument list
    Type*[] funcArgs;
    // Even if the return type is a tuple, it's still really only a single type
    Type* returnType;
    //Type*[] returnType;
    // Indicates whether this function pointer is a fat pointer, meaning it
    // contains not only the pointer to the function, but an environment
    // pointer to be passed as an argument to the function as well
    bool isFatPtr;

    FuncPtrType* copy()
    {
        auto c = new FuncPtrType();
        c.isFatPtr = this.isFatPtr;
        c.returnType = this.returnType.copy;
        c.funcArgs = this.funcArgs
                         .map!(a => a.copy)
                         .array;
        return c;
    }

    // The syntax for function pointers is not yet decided, so this is temporary
    string format()
    {
        string str = "";
        str ~= "funcptr((";
        if (funcArgs.length > 0)
        {
            str ~= funcArgs.map!(a => a.format()).join(", ") ~ "): ";
        }
        str ~= returnType.format() ~ ")";
        return str;
    }
}

struct StructMember
{
    string name;
    Type* type;

    StructMember copy()
    {
        auto c = StructMember();
        c.name = this.name;
        c.type = this.type.copy;
        return c;
    }

    string format()
    {
        return name ~ " : " ~ type.format() ~ ";";
    }
}

struct StructType
{
    string name;
    string[] templateParams;
    StructMember[] members;

    StructType* copy()
    {
        auto c = new StructType();
        c.name = this.name;
        c.templateParams = this.templateParams;
        c.members = this.members
                        .map!(a => a.copy)
                        .array;
        return c;
    }

    string format()
    {
        string str = "";
        str ~= "struct " ~ name;
        if (templateParams.length > 0)
        {
             str ~= "(" ~ templateParams.join(", ") ~ ")";
        }
        str ~= " {\n";
        foreach (member; members)
        {
            str ~= "    " ~ member.format() ~ "\n";
        }
        str ~=  "}";
        return str;
    }

    // Attempt to replace the template name placeholders with actual types
    // using a passed name: string -> concrete-type: Type* map
    void instantiate(Type*[string] mappings)
    {
        mixin descend;

        auto missing = mappings.keys.setSymmetricDifference(templateParams);
        if (missing.walkLength > 0)
        {
            "StructType.instantiate(): The passed mapping does not contain\n"
            "  keys that correspond exactly with the known template parameter\n"
            "  names. Not attempting to instantiate.\n"
            "  The missing mappings are: ".writeln;
            foreach (name; missing)
            {
                writeln("  ", name);
            }
        }
        foreach (ref member; members)
        {
            descend(member.type);
        }
        templateParams = [];
    }
}

struct VariantMember
{
    string constructorName;
    Type*[] constructorElems;

    VariantMember copy()
    {
        auto c = VariantMember();
        c.constructorName = this.constructorName;
        c.constructorElems = this.constructorElems
                                 .map!(a => a.copy)
                                 .array;
        return c;
    }

    string format()
    {
        string str = "";
        str ~= constructorName;
        if (constructorElems.length > 0)
        {
            str ~= " (" ~ constructorElems[0].format();
            if (constructorElems.length > 1)
            {
                foreach (elem; constructorElems[1..$])
                {
                    str ~= ", " ~ elem.format();
                }
            }
            str ~= ")";
        }
        return str;
    }
}

struct VariantType
{
    string name;
    string[] templateParams;
    VariantMember[] members;

    VariantType* copy()
    {
        auto c = new VariantType();
        c.name = this.name;
        c.templateParams = this.templateParams;
        c.members = this.members
                        .map!(a => a.copy)
                        .array;
        return c;
    }

    string format()
    {
        string str = "";
        str ~= "variant " ~ name;
        if (templateParams.length > 0)
        {
            str ~= "(" ~ templateParams.join(", ") ~ ")";
        }
        str ~= " {\n";
        foreach (member; members)
        {
            str ~= "    " ~ member.format() ~ "\n";
        }
        str ~= "}";
        return str;
    }

    // Attempt to replace the template name placeholders with actual types
    // using a passed name: string -> concrete-type: Type* map
    void instantiate(Type*[string] mappings)
    {
        mixin descend;

        auto missing = mappings.keys.setSymmetricDifference(templateParams);
        if (missing.walkLength > 0)
        {
            "VariantType.instantiate(): The passed mapping does not contain\n"
            "  keys that correspond exactly with the known template parameter\n"
            "  names. Not attempting to instantiate.\n"
            "  The missing mappings are: ".writeln;
            foreach (name; missing)
            {
                writeln("  ", name);
            }
        }
        foreach (ref member; members)
        {
            foreach (ref elemType; member.constructorElems)
            {
                descend(elemType);
            }
        }
        templateParams = [];
    }
}

struct Type
{
    TypeEnum tag;
    bool refType;
    bool constType;
    union {
        ArrayType* array;
        HashType* hash;
        SetType* set;
        AggregateType* aggregate;
        TupleType* tuple;
        FuncPtrType* funcPtr;
        StructType* structDef;
        VariantType* variantDef;
    };

    Type* copy()
    {
        auto c = new Type();
        c.tag = this.tag;
        c.refType = this.refType;
        c.constType = this.constType;
        final switch (tag)
        {
        case TypeEnum.VOID:
        case TypeEnum.LONG:
        case TypeEnum.INT:
        case TypeEnum.SHORT:
        case TypeEnum.BYTE:
        case TypeEnum.FLOAT:
        case TypeEnum.DOUBLE:
        case TypeEnum.CHAR:
        case TypeEnum.BOOL:
        case TypeEnum.STRING:
            break;
        case TypeEnum.SET:
            c.set = this.set.copy;
            break;
        case TypeEnum.HASH:
            c.hash = this.hash.copy;
            break;
        case TypeEnum.ARRAY:
            c.array = this.array.copy;
            break;
        case TypeEnum.TUPLE:
            c.tuple = this.tuple.copy;
            break;
        case TypeEnum.FUNCPTR:
            c.funcPtr = this.funcPtr.copy;
            break;
        case TypeEnum.STRUCT:
            c.structDef = this.structDef.copy;
            break;
        case TypeEnum.VARIANT:
            c.variantDef = this.variantDef.copy;
            break;
        case TypeEnum.AGGREGATE:
            c.aggregate = this.aggregate.copy;
            break;
        }
        return c;
    }

    string format()
    {
        string str = "";
        if (constType)
        {
            str ~= "const ";
        }
        if (refType)
        {
            str ~= "ref ";
        }
        final switch (tag)
        {
        case TypeEnum.VOID      : return str ~ "void";
        case TypeEnum.LONG      : return str ~ "long";
        case TypeEnum.INT       : return str ~ "int";
        case TypeEnum.SHORT     : return str ~ "short";
        case TypeEnum.BYTE      : return str ~ "byte";
        case TypeEnum.FLOAT     : return str ~ "float";
        case TypeEnum.DOUBLE    : return str ~ "double";
        case TypeEnum.CHAR      : return str ~ "char";
        case TypeEnum.BOOL      : return str ~ "bool";
        case TypeEnum.STRING    : return str ~ "string";
        case TypeEnum.SET       : return str ~ set.format();
        case TypeEnum.HASH      : return str ~ hash.format();
        case TypeEnum.ARRAY     : return str ~ array.format();
        case TypeEnum.AGGREGATE : return str ~ aggregate.format();
        case TypeEnum.TUPLE     : return str ~ tuple.format();
        case TypeEnum.FUNCPTR   : return str ~ funcPtr.format();
        case TypeEnum.STRUCT    : return str ~ structDef.format();
        case TypeEnum.VARIANT   : return str ~ variantDef.format();
        }
    }

    bool opEquals(const Type o) const
    {
        if (constType != o.constType
            || refType != o.refType
            || tag != o.tag)
        {
            return false;
        }
        final switch (tag)
        {
        case TypeEnum.VOID:
        case TypeEnum.LONG:
        case TypeEnum.INT:
        case TypeEnum.SHORT:
        case TypeEnum.BYTE:
        case TypeEnum.FLOAT:
        case TypeEnum.DOUBLE:
        case TypeEnum.CHAR:
        case TypeEnum.BOOL:
        case TypeEnum.STRING:
            return true;
        case TypeEnum.SET:
            return set.setType == o.set.setType;
        case TypeEnum.HASH:
            return hash.keyType == o.hash.keyType
                && hash.valueType == o.hash.valueType;
        case TypeEnum.ARRAY:
            return array.arrayType == o.array.arrayType;
        case TypeEnum.TUPLE:
            return tuple.types.length == o.tuple.types.length
                && zip(tuple.types, o.tuple.types)
                  .map!(a => a[0] == a[1])
                  .reduce!((a, b) => true == a && a == b);
        case TypeEnum.FUNCPTR:
            return funcPtr.isFatPtr == o.funcPtr.isFatPtr
                && funcPtr.returnType == o.funcPtr.returnType
                && funcPtr.funcArgs.length == o.funcPtr.funcArgs.length
                && zip(funcPtr.funcArgs,
                       o.funcPtr.funcArgs)
                  .map!(a => a[0] == a[1])
                  .reduce!((a, b) => true == a && a == b);
        case TypeEnum.STRUCT:
            return structDef.name == o.structDef.name
                && structDef.members.length == o.structDef.members.length
                && zip(structDef.members,
                       o.structDef.members)
                  .map!(a => a[0].type == a[1].type)
                  .reduce!((a, b) => true == a && a == b);
        case TypeEnum.VARIANT:
            return variantDef.name == o.variantDef.name
                && zip(variantDef.members,
                       o.variantDef.members)
                  .map!(a => a[0].constructorName == a[1].constructorName
                          && a[0].constructorElems.length
                             == a[1].constructorElems.length
                          && zip(a[0].constructorElems, a[1].constructorElems)
                            .map!(b => b[0] == b[1])
                            .reduce!((a, b) => true == a && a == b))
                  .reduce!((a, b) => true == a && a == b);
        // Aggregate types are simply placeholders for instantiated struct and
        // variant types. If we are comparing against an aggregate, we failed
        // to perform an instantiation somewhere
        case TypeEnum.AGGREGATE:
            throw new Exception("Aggregate type was not instantiated");
            //return zip(aggregate.templateInstantiations,
            //           o.aggregate.templateInstantiations)
            //      .map!(a => a[0] == a[1])
            //      .reduce!((a, b) => true == a && a == b)
            //    && aggregate.typeName == o.aggregate.typeName;
        }
    }
}

// This is mixed into the StructType and VariantType instantiate() definitions,
// as the code is exactly the same for both, but they each need closure access
// to the "mappings" argument of the instantiate() function, and passing
// the "mappings" as an argument to this function is silly since it would never
// change on each recursion, and there doesn't seem to be a way to pass the
// argument as a const variable without having to cast the constness off when
// trying to assign pointer values in the mappings back to the member types,
// which is gross
mixin template descend()
{
    // Recursively descend the type, looking for aggregate entries that
    // are in the mapping. An aggregate type is defined simply as a string
    // referring to its actual type, which means it is either referring to
    // a struct or variant definition, or is a template placeholder.
    // Even though the parent is null, the case of the top level type
    // being an aggregate is handled correctly
    void descend(ref Type* typeMember, Type* typeParent = null)
    {
        // Used to know which of the two sides of a hash type we're dealing
        // with after a descension
        static index = 0;
        switch (typeMember.tag)
        {
        // If the type is an aggregate, it is either a template placeholder
        // or not. If it is, and this is the top level call of descend, then
        // simply update the type member with its new type. If we're in
        // a recursion of descend, then update the parent's pointer to this
        // type with the new type
        case TypeEnum.AGGREGATE:
            if (typeMember.aggregate.typeName in mappings)
            {
                if (typeParent is null)
                {
                    typeMember = mappings[typeMember.aggregate.typeName];
                }
                else
                {
                    switch(typeParent.tag)
                    {
                    case TypeEnum.SET:
                        typeParent.set.setType =
                            mappings[typeMember.aggregate.typeName];
                        break;
                    case TypeEnum.HASH:
                        switch (index)
                        {
                        case 0:
                            typeParent.hash.keyType =
                                mappings[typeMember.aggregate.typeName];
                            break;
                        default:
                            typeParent.hash.valueType =
                                mappings[typeMember.aggregate.typeName];
                            break;
                        }
                        break;
                    case TypeEnum.ARRAY:
                        typeParent.array.arrayType =
                            mappings[typeMember.aggregate.typeName];
                        break;
                    default:
                        break;
                    }
                }
            }
            else
            {
                foreach (ref inner; typeMember.aggregate.templateInstantiations)
                {
                    descend(inner);
                }
            }
            break;
        case TypeEnum.SET:
            descend(typeMember.set.setType, typeMember);
            break;
        case TypeEnum.HASH:
            index = 0;
            descend(typeMember.hash.keyType, typeMember);
            index = 1;
            descend(typeMember.hash.valueType, typeMember);
            break;
        case TypeEnum.ARRAY:
            descend(typeMember.array.arrayType, typeMember);
            break;
        default:
            break;
        }
    }
}

mixin template TypeVisitors()
{
    string[] templateParams;
    Type*[][] builderStack;

    void visit(TypeIdNode node)
    {
        node.children[0].accept(this);
    }

    void visit(BasicTypeNode node)
    {
        auto basicType = (cast(ASTTerminal)node.children[0]).token;
        auto builder = new Type();
        final switch (basicType)
        {
        case "long"  : builder.tag = TypeEnum.LONG;   break;
        case "int"   : builder.tag = TypeEnum.INT;    break;
        case "short" : builder.tag = TypeEnum.SHORT;  break;
        case "byte"  : builder.tag = TypeEnum.BYTE;   break;
        case "float" : builder.tag = TypeEnum.FLOAT;  break;
        case "double": builder.tag = TypeEnum.DOUBLE; break;
        case "char"  : builder.tag = TypeEnum.CHAR;   break;
        case "bool"  : builder.tag = TypeEnum.BOOL;   break;
        case "string": builder.tag = TypeEnum.STRING; break;
        }
        builderStack[$-1] ~= builder;
    }

    void visit(ArrayTypeNode node)
    {
        node.children[0].accept(this);
        auto array = new ArrayType();
        array.arrayType = builderStack[$-1][$-1];
        auto type = new Type();
        type.tag = TypeEnum.ARRAY;
        type.array = array;
        builderStack[$-1] = builderStack[$-1][0..$-1] ~ type;
    }

    void visit(SetTypeNode node)
    {
        node.children[0].accept(this);
        auto set = new SetType();
        set.setType = builderStack[$-1][$-1];
        auto type = new Type();
        type.tag = TypeEnum.SET;
        type.set = set;
        builderStack[$-1] = builderStack[$-1][0..$-1] ~ type;
    }

    void visit(HashTypeNode node)
    {
        node.children[0].accept(this);
        node.children[1].accept(this);
        auto hash = new HashType();
        hash.keyType = builderStack[$-1][$-2];
        hash.valueType = builderStack[$-1][$-1];
        auto type = new Type();
        type.tag = TypeEnum.HASH;
        type.hash = hash;
        builderStack[$-1] = builderStack[$-1][0..$-2] ~ type;
    }

    void visit(UserTypeNode node)
    {
        node.children[0].accept(this);
        string userTypeName = id;
        auto aggregate = new AggregateType();
        aggregate.typeName = userTypeName;
        if (node.children.length > 1)
        {
            builderStack.length++;
            node.children[1].accept(this);
            aggregate.templateInstantiations = builderStack[$-1];
            builderStack.length--;
        }
        auto type = new Type();
        type.tag = TypeEnum.AGGREGATE;
        type.aggregate = aggregate;
        builderStack[$-1] ~= type;
    }

    void visit(TypeTupleNode node)
    {
        auto tuple = new TupleType();
        foreach (child; node.children)
        {
            child.accept(this);
            tuple.types ~= builderStack[$-1][$-1];
            builderStack[$-1] = builderStack[$-1][0..$-1];
        }
        auto type = new Type();
        type.tag = TypeEnum.TUPLE;
        type.tuple = tuple;
        builderStack[$-1] ~= type;
    }

    void visit(ChanTypeNode node)
    {

    }

    void visit(TemplateTypeParamsNode node)
    {
        if (node.children.length > 0)
        {
            // Visit TemplateTypeParamListNode
            node.children[0].accept(this);
        }
    }

    void visit(TemplateTypeParamListNode node)
    {
        templateParams = [];
        foreach (child; node.children)
        {
            child.accept(this);
            templateParams ~= id;
        }
    }

    void visit(TemplateInstantiationNode node)
    {
        node.children[0].accept(this);
    }

    void visit(TemplateParamNode node)
    {
        node.children[0].accept(this);
    }

    void visit(TemplateParamListNode node)
    {
        foreach (child; node.children)
        {
            child.accept(this);
        }
    }

    void visit(TemplateAliasNode node)
    {
        node.children[0].accept(this);
    }
}

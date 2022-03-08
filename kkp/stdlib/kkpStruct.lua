local kkp_structN = require("kkp.struct")

-- 注册一个结构体，注册的目的是为了可以在 lua 里创建结构体，并使用可读性高的 key 去访问数据
function kkp_struct(struct_define)
    kkp_structN.registerStruct(struct_define)
end

-- 预注册通用结构体
kkp_struct({name = "CGSize", types = "CGFloat,CGFloat", keys = "width,height"})
kkp_struct({name = "CGPoint", types = "CGFloat,CGFloat", keys = "x,y"})
kkp_struct({name = "UIEdgeInsets", types = "CGFloat,CGFloat,CGFloat,CGFloat", keys = "top,left,bottom,right"})
kkp_struct({name = "CGRect", types = "CGFloat,CGFloat,CGFloat,CGFloat", keys = "x,y,width,height"})
kkp_struct({name = "NSRange", types = "NSUInteger,NSUInteger", keys = "location,length"})
kkp_struct({name = "_NSRange", types = "NSUInteger,NSUInteger", keys = "location,length"})--typedef _NSRange to NSRange
kkp_struct({name = "CLLocationCoordinate2D", types = "CGFloat,CGFloat", keys = "latitude,longitude"})
kkp_struct({name = "MKCoordinateSpan", types = "CGFloat,CGFloat", keys = "latitudeDelta,longitudeDelta"})
kkp_struct({name = "MKCoordinateRegion", types = "CGFloat,CGFloat,CGFloat,CGFloat", keys = "latitude,longitude,latitudeDelta,longitudeDelta"})
kkp_struct({name = "CGAffineTransform", types = "CGFloat,CGFloat,CGFloat,CGFloat,CGFloat,CGFloat", keys = "a,b,c,d,tx,ty"})
kkp_struct({name = "UIOffset", types = "CGFloat,CGFloat", keys = "horizontal,vertical"})

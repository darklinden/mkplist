//
//  main.m
//  mkplist
//
//  Created by HanShaokun on 13/11/15.
//  Copyright (c) 2015 by. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSMutableArray *keys = [NSMutableArray array];
        NSMutableArray *values = [NSMutableArray array];
        bool start = false;
        
        for (int i = 0; i < argc; i++) {
            NSString* tmp = [NSString stringWithUTF8String:argv[i]];
            
            if ([tmp hasPrefix:@"-"]) {
                [keys addObject:[tmp substringFromIndex:1]];
                start = true;
            }
            else {
                if (start) {
                    [values addObject:tmp];
                }
            }
        }
        
        if (!keys.count || keys.count != values.count) {
            printf("mkplist 参数:\n");
            printf("-s              // 源文件 \n"
                   "-d              // 目标文件 \n "
                   "-urlstr         // 下载链接 \n"
                   "-identifier     // bundle-identifier \n"
                   "-version        // bundle-version \n"
                   "-title          // title\n");
            return -1;
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        
        NSString* src = dict[@"s"];
        NSString* des = dict[@"d"];
        NSString* urlstr = dict[@"urlstr"];
        NSString* identifier = dict[@"identifier"];
        NSString* version = dict[@"version"];
        NSString* title = dict[@"title"];
        
        if (![src hasPrefix:@"/"]) {
            char buf[1024];
            getcwd(buf, sizeof(buf));
            src = [[NSString stringWithUTF8String:buf] stringByAppendingPathComponent:src];
        }
        
        if (![des hasPrefix:@"/"]) {
            char buf[1024];
            getcwd(buf, sizeof(buf));
            des = [[NSString stringWithUTF8String:buf] stringByAppendingPathComponent:des];
        }
        
        NSFileManager* fmgr = [NSFileManager defaultManager];
        
        NSMutableDictionary *plist_dict = [NSMutableDictionary dictionaryWithContentsOfFile:src];
        
        if (!plist_dict) {
            NSLog(@"打开 [%@] 失败", dict);
            return -1;
        }
        
        NSMutableArray *items = [NSMutableArray arrayWithArray:plist_dict[@"items"]];
        
        NSMutableDictionary *itemdict = [NSMutableDictionary dictionaryWithDictionary:items.firstObject];
        
        {
            NSMutableArray* tmparr = [NSMutableArray arrayWithArray:itemdict[@"assets"]];
            NSMutableDictionary* tmpdict = [NSMutableDictionary dictionaryWithDictionary:tmparr.firstObject];

            tmpdict[@"url"] = urlstr;
            
            [tmparr replaceObjectAtIndex:0 withObject:tmpdict];
            itemdict[@"assets"] = tmparr;
        }
        
        {
            NSMutableDictionary* tmpdict = [NSMutableDictionary dictionaryWithDictionary:itemdict[@"metadata"]];
            tmpdict[@"bundle-identifier"] = identifier;
            tmpdict[@"bundle-version"] = version;
            tmpdict[@"title"] = [NSString stringWithFormat:@"%@", title];
            itemdict[@"metadata"] = tmpdict;
        }
        
        [items replaceObjectAtIndex:0 withObject:itemdict];
        plist_dict[@"items"] = items;
        
        [fmgr removeItemAtPath:des error:nil];
        if (![plist_dict writeToFile:des atomically:YES]) {
            NSLog(@"修改失败");
            return -1;
        }
        else {
            NSLog(@"成功创建 %@", des.lastPathComponent);
        }
    }
    return 0;
}

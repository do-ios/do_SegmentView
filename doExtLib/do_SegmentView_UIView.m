//
//  do_SegmentView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SegmentView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonHelper.h"
#import "doYZTopScrollView.h"
#import "doServiceContainer.h"
#import "doIUIModuleFactory.h"
#import "doILogEngine.h"

@interface do_SegmentView_UIView()<doYZTopScrollViewDelegate>
{
    NSMutableArray *_cellTemplatesArray;
    id<doIListData> _dataArrays;
    NSMutableArray *_subViewArray;
    doYZTopScrollView *yzTopScrollView;
    
//    NSInteger _oldIndex;
}
@property (nonatomic , assign) NSInteger currentPage;
@end

@implementation do_SegmentView_UIView
{
    NSMutableDictionary *_modules;
    
    BOOL _isFirstLoaded;
}
@synthesize currentPage = _currentPage;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _subViewArray = [NSMutableArray array];
    _cellTemplatesArray = [NSMutableArray array];
//    _oldIndex = -1;
    _modules = [NSMutableDictionary dictionary];
    
    NSString *defaultIndex = [_model GetProperty:@"index"].DefaultValue;
    [_model SetPropertyValue:@"index" :defaultIndex];
    
    [self.layer setMasksToBounds:YES];
    
    _isFirstLoaded = YES;
}
//销毁所有的全局对象
- (void) OnDispose
{
    [yzTopScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [yzTopScrollView removeFromSuperview];
    yzTopScrollView = nil;
    [_subViewArray removeAllObjects];
    _subViewArray = [NSMutableArray array];
    [self clearModule];
    [_cellTemplatesArray removeAllObjects];
    _cellTemplatesArray = nil;
    [ (doModule*)_dataArrays Dispose];
    _model = nil;
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    BOOL isAutoWidth = [[_model GetPropertyValue:@"width"] isEqualToString:@"-1"];
    if (isAutoWidth) {
        self.frame = CGRectMake(_model.RealX, _model.RealY, CGRectGetWidth(self.frame), _model.RealHeight);
    }else
        [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_index:(NSString *)newValue
{
//    if (_oldIndex == [newValue integerValue]) {
//        return;
//    }
//    _oldIndex = [newValue integerValue];
    //自己的代码实现

    int no = 0;
    if (!newValue || [newValue isEqualToString:@""]) {
        no = 0;
    }else{
        no = [newValue intValue];
    }
    [self fireEvent:@(no) :1];
    _currentPage = no;
    if (_subViewArray.count > 0) {
        [yzTopScrollView adjustScrollViewContentX:[_subViewArray objectAtIndex:self.currentPage] :YES];
    }
}
- (void)fireEvent:(NSNumber *)index :(int)type
{
    //完善proddev-5629
    if (type==2) {
        if (_currentPage == [index intValue]) {
            return;
        } else {
            _currentPage = [index intValue];
        }
        
    }
    //proddev-5629
//    if (_currentPage == [[_model GetPropertyValue:@"index"] integerValue]){
//        return;
//    }

    
//    if (type == 2) {
//        if (_currentPage == [[_model GetPropertyValue:@"index"] integerValue]){
//            return;
//        }
//    }
    [_model SetPropertyValue:@"index" :[index stringValue]];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [invokeResult SetResultInteger:[index intValue]];
    [_model.EventCenter FireEvent:@"indexChanged" :invokeResult];
}
- (NSInteger)currentPage
{
    NSInteger num = _currentPage;
    if (_subViewArray.count>0) {
        if (num<0) {
            num = 0;
        }else if(num >= _subViewArray.count)
            num = _subViewArray.count-1;
    }else
        num = 0;
    return num;
}

- (void)change_templates:(NSString *)newValue
{
    //自己的代码实现
    NSArray *arrays = [newValue componentsSeparatedByString:@","];
    [_cellTemplatesArray removeAllObjects];
    for(int i=0;i<arrays.count;i++)
    {
        NSString *modelStr = arrays[i];
        if(modelStr != nil && ![modelStr isEqualToString:@""])
        {
            [_cellTemplatesArray addObject:modelStr];
        }
    }
    [self clearModule];
}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doSegmentView" format:@"未指定相关的doSegmentView data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scritEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doSegmentView" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])//hash
        {
            if(_dataArrays!= bindingModule)
            {
                _dataArrays = bindingModule;
            }
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }

    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];

    }
}
- (void)refreshItems:(NSArray *)parms
{
    [self getSegmentView];
    _isFirstLoaded = NO;
}

- (void)clearModule
{
    [_modules.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(NSArray *)obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(doUIModule *)obj Dispose];
        }];
        [(NSMutableArray *)obj removeAllObjects];
    }];
    [_modules removeAllObjects];
    _modules = nil;
}

- (id)getModule:(int)index
{
    NSString *num = [@(index) stringValue];
    NSArray *a = [_modules objectForKey:num];
    if (a.count == 0) {
        return nil;
    }else{
        for (id obj in a) {
            UIView *view = (UIView*)(((doUIModule*)obj).CurrentUIModuleView);
            if (![_subViewArray containsObject:view]) {
                return obj;
                break;
            }
        }
    }
    return nil;
}

- (void)getSegmentView
{
    [_subViewArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [((UIView *)obj) removeFromSuperview];
    }];
    [_subViewArray removeAllObjects];
    _subViewArray = [NSMutableArray array];
    doUIModule *showCellMode;
    NSString* indentify;
    for (int i = 0; i < [_dataArrays GetCount]; i ++) {
        id jsonValue = [_dataArrays GetData:i];
        NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
        int cellIndex = [doJsonHelper GetOneInteger:dataNode :@"template" :0];
        if (cellIndex >= _cellTemplatesArray.count || cellIndex<0) {
            cellIndex = 0;
        }
        showCellMode = (doUIModule *)[self getModule:cellIndex];
        if (!showCellMode) {
            indentify = _cellTemplatesArray[cellIndex];
            @try
            {
                showCellMode = [[doServiceContainer Instance].UIModuleFactory CreateUIModuleBySourceFile:indentify :_model.CurrentPage :YES];
                if (showCellMode) {
                    NSString *index = [@(cellIndex) stringValue];
                    NSMutableArray *a = [NSMutableArray arrayWithArray:[_modules objectForKey:index]];

                    [a addObject:showCellMode];
                    [_modules setObject:a forKey:index];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@",exception.description);
                [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
                doInvokeResult* _result = [[doInvokeResult alloc]init];
                [_result SetException:exception];
            }
        }

        UIView *subView = (UIView*)showCellMode.CurrentUIModuleView;
        id<doIUIModuleView> modelView =((doUIModule*) showCellMode).CurrentUIModuleView;
        [showCellMode SetModelData:jsonValue];
        [modelView OnRedraw];

        [_subViewArray addObject:subView];
    }

    if (!yzTopScrollView) {
        yzTopScrollView = [doYZTopScrollView new];
        BOOL isAutoWidth = [[_model GetPropertyValue:@"width"] isEqualToString:@"-1"];
        yzTopScrollView.isAutoWidth = isAutoWidth;
        yzTopScrollView.frame = CGRectMake(0, 0, _model.RealWidth, _model.RealHeight);
        yzTopScrollView.yzDelegate = self;
        [self addSubview:yzTopScrollView];
    }
    yzTopScrollView.subViewArray = _subViewArray;
    
    if (_isFirstLoaded) {
        if (_subViewArray.count > 0) {
            [yzTopScrollView adjustScrollViewContentX:[_subViewArray objectAtIndex:self.currentPage] :YES];
        }
    }
}

#pragma - mark
#pragma mark doYZTopScrollViewDelegate代理方法
- (void)didTapSubView:(NSNumber *)currentIndex
{
    [self fireEvent:currentIndex :2];
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end

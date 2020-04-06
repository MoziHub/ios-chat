//
//  SeletedUserViewController.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/2.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUSeletedUserViewController.h"
#import "WFCUSelectedUserCollectionViewCell.h"
#import "WFCUSelectedUserTableViewCell.h"
#import "WFCUUserSectionKeySupport.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "UIImage+ERCategory.h"
#import "WFCUConfigManager.h"
#import "WFCUSeletedUserSearchResultViewController.h"
#import "UIView+Toast.h"

#define SearchBarMinWidth 150
//#import "WFCCIMService.h"
@interface WFCUSeletedUserViewController ()
<UITableViewDataSource, UITableViewDelegate,
UICollectionViewDelegate, UICollectionViewDataSource,
UISearchBarDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UIView *topView;
@property (nonatomic, strong)UICollectionView *selectedUserCollectionView;
@property (nonatomic, strong)UISearchBar *searchBar;

@property (nonatomic, strong)UIButton *doneButton;
@property (nonatomic, strong)NSMutableArray<WFCUSelectedUserInfo *> *dataSource;
@property (nonatomic, strong)NSDictionary *sectionDictionary;
@property (nonatomic, strong)NSArray *sectionKeys;
@property(nonatomic, assign)BOOL sorting;
@property(nonatomic, assign)BOOL needSort;
@property (nonatomic, strong)NSMutableArray<WFCUSelectedUserInfo *> *selectedUsers;
@end

@implementation WFCUSeletedUserViewController



- (void)loadData {
    self.dataSource = [NSMutableArray new];
    self.selectedUsers = [NSMutableArray new];
    NSArray *userDataSource = nil;
    
    if (self.inputData) {
        userDataSource = self.inputData;
    } else if (self.candidateUsers) {
        userDataSource = [[WFCCIMService sharedWFCIMService] getUserInfos:self.candidateUsers inGroup:nil];
    } else {
        NSArray *userIdList = [[WFCCIMService sharedWFCIMService] getMyFriendList:YES];
        userDataSource = [[WFCCIMService sharedWFCIMService] getUserInfos:userIdList inGroup:nil];
    }
    
    for (WFCCUserInfo *userInfo in userDataSource) {
        WFCUSelectedUserInfo *info = [[WFCUSelectedUserInfo alloc] init];
        [info cloneFrom:userInfo];
        if ([self.disableUserIds containsObject:info.userId]) {
            info.selectedStatus = Disable;
        }
        [self.dataSource addObject:info];
    }
    
    
    [self sortAndRefreshWithList:self.dataSource];
}

- (void)setUpUI {
    
    if (self.type != No) {
        [self.view addSubview:self.topView];
        [self.topView addSubview:self.searchBar];
        [self.topView addSubview:self.selectedUserCollectionView];
    }
    [self.view addSubview:self.tableView];
    if (self.type == Vertical) {
        self.view.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        self.tableView.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        self.searchBar.barTintColor = [UIColor colorWithHexString:@"313236"];
        self.selectedUserCollectionView.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor colorWithHexString:@"313236"] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:@"0x1f2026"];
        UINavigationBar *bar = [UINavigationBar appearance];
        bar.barTintColor = [UIColor colorWithHexString:@"0x1f2026"];
        bar.tintColor = [UIColor whiteColor];
        bar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
        bar.barStyle = UIBarStyleDefault;
        
        if (@available(iOS 13, *)) {
            UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
            bar.standardAppearance = navBarAppearance;
            bar.scrollEdgeAppearance = navBarAppearance;
            navBarAppearance.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
            navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
        }
        self.title = @"选择成员";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
        
        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneButton.frame = CGRectMake(0, 0, 52, 30);
        [self setDoneButtonStyleAndContent:NO];
        self.doneButton.backgroundColor = [UIColor colorWithHexString:@"0x3e65e4"];
        [self.doneButton setTitle:@"完成" forState:UIControlStateNormal];
        self.doneButton.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
        [self.doneButton setTintColor:[UIColor whiteColor]];
        self.doneButton.layer.cornerRadius = 4;
        self.doneButton.layer.masksToBounds = YES;
        self.doneButton.enabled = NO;
        [self.doneButton addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];
        
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.selectedUserCollectionView.backgroundColor = [UIColor whiteColor];
        self.searchBar.barTintColor = [UIColor whiteColor];
        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
        self.title = @"创建会话";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
        
        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneButton.frame = CGRectMake(0, 0, 52, 30);
        [self setDoneButtonStyleAndContent:NO];
        self.doneButton.backgroundColor = [UIColor colorWithHexString:@"0x3e65e4"];
        [self.doneButton setTitle:@"完成" forState:UIControlStateNormal];
        self.doneButton.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:15];
        [self.doneButton setTintColor:[UIColor whiteColor]];
        self.doneButton.layer.cornerRadius = 4;
        self.doneButton.layer.masksToBounds = YES;
        self.doneButton.enabled = NO;
        [self.doneButton addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.doneButton];
        
    }
}

- (void)setDoneButtonStyleAndContent:(BOOL)enable {
    if (enable) {
        self.doneButton.enabled = YES;
        self.doneButton.alpha = 1.0;
        
        if (self.type == Horizontal) {
            [self.doneButton setTitle:[NSString stringWithFormat:@"完成(%lu)", (unsigned long)self.selectedUsers.count] forState:UIControlStateNormal];
            [self.doneButton sizeToFit];
            self.doneButton.frame = CGRectMake(0, 0, self.doneButton.frame.size.width + 8 * 2, self.doneButton.frame.size.height);
        } else {
            [self.doneButton setTitle:[NSString stringWithFormat:@"完成(%lu/%d)", (unsigned long)self.selectedUsers.count, self.maxSelectCount] forState:UIControlStateNormal];
                    [self.doneButton sizeToFit];
                    self.doneButton.frame = CGRectMake(0, 0, self.doneButton.frame.size.width + 8 * 2, self.doneButton.frame.size.height);
        }

    } else {
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6;
        self.doneButton.frame = CGRectMake(0, 0, 52, 30);
        [self.doneButton setTitle:@"完成" forState:UIControlStateNormal];

    }
}

- (void)cancel {
    UINavigationBar *bar = [UINavigationBar appearance];
    bar.barTintColor = [WFCUConfigManager globalManager].naviBackgroudColor;
    bar.tintColor = [WFCUConfigManager globalManager].naviTextColor;
    bar.titleTextAttributes = @{NSForegroundColorAttributeName : [WFCUConfigManager globalManager].naviTextColor};
    bar.barStyle = UIBarStyleDefault;
    
    if (@available(iOS 13, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        bar.standardAppearance = navBarAppearance;
        bar.scrollEdgeAppearance = navBarAppearance;
        navBarAppearance.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        navBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName:[WFCUConfigManager globalManager].naviTextColor};
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)finish {
    NSMutableArray *selectedUserIds = [NSMutableArray new];
    for (WFCUSelectedUserInfo *user in self.selectedUsers) {
        [selectedUserIds addObject:user.userId];
    }
    self.selectResult(selectedUserIds);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData];
    [self setUpUI];
    
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self resizeAllView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        [self resizeAllView];
    }
}

- (void)resizeAllView {
    CGFloat topSpace = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    if (self.type == Vertical) {
        CGFloat collectionViewHeight = 0;
        CGSize contentSize = self.selectedUserCollectionView.contentSize;
        if (contentSize.height > 52 * 2 + 10) {
            collectionViewHeight = 52 * 2 + 10;
        } else {
            collectionViewHeight = contentSize.height;
        }
        
        self.selectedUserCollectionView.frame = CGRectMake(16, 0, self.view.frame.size.width - 16 * 2, collectionViewHeight);
        self.searchBar.frame = CGRectMake(16, collectionViewHeight + 12, self.view.frame.size.width - 16 * 2, 38);
        self.topView.frame = CGRectMake(0, topSpace, self.view.frame.size.width, collectionViewHeight + 12 + 26 + 16);
        self.tableView.frame = CGRectMake(0, topSpace + collectionViewHeight + 12 + 26 + 16, self.view.frame.size.width, self.view.frame.size.height - (collectionViewHeight + 12 + 26 + 16));
    } else {
        CGFloat collectionViewWidth = 0;
        CGFloat collectionMaxWidth = self.view.frame.size.width - (16 + SearchBarMinWidth + 8 * 2);
        CGSize contentSize = self.selectedUserCollectionView.contentSize;
        if (contentSize.width > collectionMaxWidth) {
            collectionViewWidth = collectionMaxWidth;
        } else {
            collectionViewWidth = contentSize.width;
        }
        self.selectedUserCollectionView.frame = CGRectMake(16, 6, collectionViewWidth, 24);
        self.searchBar.frame = CGRectMake(16 + collectionViewWidth + 8, 0, self.view.frame.size.width - (16 + collectionViewWidth + 8 * 2), 36);
        self.topView.frame = CGRectMake(0, topSpace, self.view.frame.size.width, 44);
        self.tableView.frame = CGRectMake(0, topSpace + 44, self.view.frame.size.width, self.view.frame.size.height - 44);
        
    }
    
}


- (UICollectionView *)selectedUserCollectionView {
    if (!_selectedUserCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        
        CGRect rect = CGRectZero;
        if (self.type == Vertical) {
            flowLayout.itemSize = CGSizeMake(52, 52);
            flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
            rect = CGRectMake(16, 0, self.view.frame.size.width - 16 * 2, 1);
        } else {
            flowLayout.itemSize = CGSizeMake(24, 24);
            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            rect = CGRectMake(16, 6, 1, 24);
            
        }
        
        _selectedUserCollectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:flowLayout];
        _selectedUserCollectionView.delegate = self;
        _selectedUserCollectionView.dataSource = self;
        [_selectedUserCollectionView registerClass:[WFCUSelectedUserCollectionViewCell class] forCellWithReuseIdentifier:@"selectedUserC"];
        [_selectedUserCollectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _selectedUserCollectionView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        //        _tableView.frame = self.view.bounds;
        _tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        
        [_tableView registerClass:[WFCUSelectedUserTableViewCell class] forCellReuseIdentifier:@"selectedUserT"];
        
    }
    return _tableView;
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [UIView new];
        if (self.type == Horizontal) {
            _topView.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
            UIView *insertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 36)];
            insertView.backgroundColor = [UIColor whiteColor];
            [_topView addSubview:insertView];
        }
    }
    return _topView;
}

- (UISearchBar *)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        _searchBar.delegate = self;
        _searchBar.placeholder = @"搜索";
        _searchBar.barStyle = UIBarStyleDefault;
    }
    return _searchBar;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    WFCUSeletedUserSearchResultViewController *resultVC = [[WFCUSeletedUserSearchResultViewController alloc] init];
    __weak typeof(self)weakSelf = self;
    resultVC.dataSource = self.dataSource;
      resultVC.needSection = self.type == Horizontal;
    resultVC.selectedUser = ^(WFCUSelectedUserInfo * _Nonnull user) {
             [weakSelf refreshSeletedUser:user];
    };
    UINavigationController *naviVC = [[UINavigationController alloc] initWithRootViewController:resultVC];
    naviVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:naviVC animated:NO completion:nil];
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.type == Horizontal) {
        return self.sectionKeys.count;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.type == Horizontal) {
        NSString *key = self.sectionKeys[section];
        NSArray *users = self.sectionDictionary[key];
        return users.count;
    } else {
        return self.dataSource.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUSelectedUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectedUserT"];
    
    if (self.type == Horizontal) {
        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];
        cell.selectedUserInfo = users[indexPath.row];
    } else {
        
        cell.selectedUserInfo = self.dataSource[indexPath.row];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.type == Vertical) {
        cell.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
        cell.nameLabel.textColor = [UIColor whiteColor];
        cell.nameLabel.textColor = [UIColor whiteColor];
        
        
    } else {
        cell.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
        cell.backgroundColor = [UIColor whiteColor];
        cell.nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        
        
    }
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.type == Horizontal) {
        if (section == 0) {
            return 0;
        }
        return 30;
        
    } else {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.type == Horizontal) {
        NSString *title = self.sectionKeys[section];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        view.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];
        label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
        label.textColor = [UIColor colorWithHexString:@"0x828282"];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = [NSString stringWithFormat:@"%@", title];
        [view addSubview:label];
        return view;
        
    } else {
        return nil;
    }
}

- (BOOL)refreshSeletedUser:(WFCUSelectedUserInfo *)user {
    if (user.selectedStatus == Disable) {
        return NO;
    } else if (user.selectedStatus == Checked) {
        user.selectedStatus = Unchecked;
        NSIndexPath *removeIndexPath = [NSIndexPath indexPathForItem:[self.selectedUsers indexOfObject:user] inSection:0];
        [self.selectedUsers removeObject:user];
        [self.selectedUserCollectionView deleteItemsAtIndexPaths:@[removeIndexPath]];
    } else if (user.selectedStatus == Unchecked) {
        if (self.maxSelectCount > 0 && self.selectedUsers.count >= self.maxSelectCount) {
            [self.view makeToast:WFCString(@"MaxCount")];
            return NO;
        }
        user.selectedStatus = Checked;
        [self.selectedUsers addObject:user];
        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForItem:self.selectedUsers.count - 1 inSection:0];
        [self.selectedUserCollectionView insertItemsAtIndexPaths:@[insertIndexPath]];
    }
    [self setDoneButtonStyleAndContent:self.selectedUsers.count > 0];
    NSIndexPath *indexPath = nil;
    if (self.type == Vertical) {
       indexPath = [NSIndexPath indexPathForRow:[self.dataSource indexOfObject:user] inSection:0];
    } else {
        indexPath = [self getSectionIndexPath:user];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    return YES;
    
}

- (NSIndexPath *)getSectionIndexPath:(WFCUSelectedUserInfo *)user {
    NSIndexPath *indexPath = nil;
    
    for (NSString *key in self.sectionKeys) {
        NSArray *users = self.sectionDictionary[key];
        for (WFCUSelectedUserInfo *u in users) {
            if ([u isEqual:user]) {
                NSInteger section = [self.sectionKeys indexOfObject:key];
                NSInteger row =  [users indexOfObject:u];
                indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.type == Vertical) {
        WFCUSelectedUserInfo *user = nil;
        user = self.dataSource[indexPath.row];
        [self refreshSeletedUser:user];
    } else {
        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];
        WFCUSelectedUserInfo *user = nil;
        user = users[indexPath.row];
        [self refreshSeletedUser:user];


    }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    if (self.type == Horizontal) {
        return self.sectionKeys;
    } else {
        return nil;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUSelectedUserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"selectedUserC" forIndexPath:indexPath];
    cell.user = self.selectedUsers[indexPath.row];
    cell.isSmall = self.type == Horizontal;
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.selectedUsers.count;
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    //    self.sorting = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary *resultDic = [WFCUUserSectionKeySupport userSectionKeys:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sectionDictionary = resultDic[@"infoDic"];
            self.sectionKeys = resultDic[@"allKeys"];
            [self.tableView reloadData];
        });
    });
}

//- (void)setNeedSort:(BOOL)needSort {
//    _needSort = needSort;
//    if (needSort && !self.sorting) {
//        _needSort = NO;
//        if (self.searchController.active) {
//            [self sortAndRefreshWithList:self.searchList];
//        } else {
//            [self sortAndRefreshWithList:self.dataSource];
//        }
//    }
//}



@end

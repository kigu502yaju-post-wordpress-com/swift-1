// RUN: %empty-directory(%t)

// Check that importing this module creates the right types

// RUN: %target-swift-frontend -emit-module-interface-path %t/private-stored-members.swiftinterface -module-name PrivateStoredMembers -emit-module -o %t/PrivateStoredMembers.swiftmodule %S/private-stored-members.swift
// RUN: %target-swift-frontend %use_no_opaque_pointers -emit-ir %s -I %t 2>&1 -DSHOULD_IMPORT | %FileCheck %s --check-prefix CHECK-EXEC --check-prefix CHECK
// RUN: %target-swift-frontend -emit-ir %s -I %t 2>&1 -DSHOULD_IMPORT

// Check that the types are also correct when importing a module created from an interface

// RUN: %target-swift-frontend -emit-module -o %t/PrivateStoredMembers.swiftmodule -module-name PrivateStoredMembers %t/private-stored-members.swiftinterface -disable-objc-attr-requires-foundation-module
// RUN: %target-swift-frontend %use_no_opaque_pointers -emit-ir %s -I %t 2>&1 -DSHOULD_IMPORT | %FileCheck %s --check-prefix CHECK-EXEC --check-prefix CHECK
// RUN: %target-swift-frontend -emit-ir %s -I %t 2>&1 -DSHOULD_IMPORT

// Check the types generated when the source file is the primary file, and ensure they're the same layout.

// RUN: %target-swift-frontend %use_no_opaque_pointers -emit-ir %S/private-stored-members.swift %s 2>&1 -module-name main | %FileCheck %s --check-prefix CHECK-MAIN --check-prefix CHECK-EXEC
// RUN: %target-swift-frontend -emit-ir %S/private-stored-members.swift %s 2>&1 -module-name main

// These two appear out-of-order between run lines

// CHECK-DAG: [[MYCLASS:%T20PrivateStoredMembers7MyClassC]] = type 
// CHECK-DAG: [[MYSTRUCT:%T20PrivateStoredMembers8MyStructV]] = type <{ %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V }>

// CHECK-MAIN-DAG: [[MYCLASS:%T4main7MyClassC]] = type <{ %swift.refcounted, %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V }>
// CHECK-MAIN-DAG: [[MYSTRUCT:%T4main8MyStructV]] = type <{ %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V, %TSb, [7 x i8], %Ts5Int64V }>

#if SHOULD_IMPORT
import PrivateStoredMembers
#endif

// CHECK-EXEC: swiftcc void @"$s{{[^ ]+}}8makeUseryyF"() #0 {
public func makeUser() {
  let ptr = UnsafeMutablePointer<MyStruct>.allocate(capacity: 1)
  // CHECK-EXEC: %.publicEndVar = getelementptr inbounds [[MYSTRUCT]], [[MYSTRUCT]]* %{{[0-9]+}}, i32 0, i32 [[PUBLIC_END_VAR_IDX:12]]
  // CHECK-EXEC: %.publicEndVar._value = getelementptr inbounds %Ts5Int64V, %Ts5Int64V* %.publicEndVar, i32 0, i32 0
  // CHECK-EXEC: store i64 4, i64* %.publicEndVar._value
  ptr.pointee.publicEndVar = 4

  // CHECK-EXEC: %.publicEndVar1 = getelementptr inbounds [[MYSTRUCT]], [[MYSTRUCT]]* %{{[0-9]+}}, i32 0, i32 [[PUBLIC_END_VAR_IDX]]
  // CHECK-EXEC: %.publicEndVar1._value = getelementptr inbounds %Ts5Int64V, %Ts5Int64V* %.publicEndVar1, i32 0, i32 0
  // CHECK-EXEC: [[PUBLIC_END_VAR_LOAD:%[0-9]+]] = load i64, i64* %.publicEndVar1._value, align 8

  // CHECK-EXEC: %.publicVar = getelementptr inbounds [[MYSTRUCT]], [[MYSTRUCT]]* %{{[0-9]+}}, i32 0, i32 0
  // CHECK-EXEC: %.publicVar._value = getelementptr inbounds %Ts5Int64V, %Ts5Int64V* %.publicVar, i32 0, i32 0
  // CHECK-EXEC: store i64 [[PUBLIC_END_VAR_LOAD]], i64* %.publicVar._value, align 8
  ptr.pointee.publicVar = ptr.pointee.publicEndVar
  ptr.deallocate()

  // CHECK-EXEC: %[[MYCLASS_INIT:[0-9]+]] = call swiftcc [[MYCLASS]]* @"$s{{[^ ]+}}7MyClassCACycfC"(%swift.type* swiftself %{{[0-9]+}})
  let myClass = MyClass()

  // These are uninteresting as they just call into the standard getter and setter.
  myClass.publicEndVar = 4
  myClass.publicVar = myClass.publicEndVar
}

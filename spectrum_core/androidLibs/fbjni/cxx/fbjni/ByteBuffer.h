/*
 *  Copyright (c) 2018-present, Facebook, Inc.
 *
 *  This source code is licensed under the MIT license found in the LICENSE
 *  file in the root directory of this source tree.
 *
 */
#pragma once

#include <fbjni/fbjni.h>

namespace facebook {
namespace jni {

class JBuffer : public JavaClass<JBuffer> {
public:
  static constexpr const char* kJavaDescriptor = "Ljava/nio/Buffer;";

  void rewind() const;
};

// JNI's NIO support has some awkward preconditions and error reporting. This
// class provides much more user-friendly access.
class JByteBuffer : public JavaClass<JByteBuffer, JBuffer> {
 public:
  static constexpr const char* kJavaDescriptor = "Ljava/nio/ByteBuffer;";

  static local_ref<JByteBuffer> wrapBytes(uint8_t* data, size_t size);

  bool isDirect() const;

  uint8_t* getDirectBytes() const;
  size_t getDirectSize() const;
};

}}

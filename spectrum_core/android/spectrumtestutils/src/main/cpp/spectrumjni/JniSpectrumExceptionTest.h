// Copyright (c) Facebook, Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

#pragma once

#include <fbjni/fbjni.h>
#include <spectrumjni/JniSpectrumException.h>

namespace facebook {
namespace spectrum {

class JniSpectrumExceptionTest
    : public facebook::jni::HybridClass<JniSpectrumExceptionTest> {
 private:
  friend HybridBase;

 public:
  constexpr static auto kJavaDescriptor =
      "Lcom/facebook/spectrum/JniSpectrumExceptionTest;";

  static facebook::jni::local_ref<jhybriddata> initHybrid(
      facebook::jni::alias_ref<jhybridobject>);

  void throwSpectrumException(
      const std::string name,
      const std::string message,
      const std::string function,
      const int line);

  void throwSpectrumExceptionWithoutMessage(
      const std::string name,
      const std::string function,
      const int line);

  static void registerNatives();
};

} // namespace spectrum
} // namespace facebook

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package com.facebook.spectrum.options;

import static org.fest.assertions.api.Assertions.assertThat;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class TransformOptionsTest extends BaseOptionsTest {

  @Test
  public void testSetters_whenEverythingSet_thenBuiltObjectConforms() {
    final TransformOptions options =
        TransformOptions.Builder(mockOutputPixelSpecification)
            .configuration(mockConfiguration)
            .crop(mockCropRequirement)
            .resize(mockResizeRequirement)
            .rotate(mockRotateRequirement)
            .build();

    assertThat(options.outputPixelSpecification).isEqualTo(mockOutputPixelSpecification);
    assertThat(options.configuration).isEqualTo(mockConfiguration);
    assertThat(options.transformations.cropRequirement).isEqualTo(mockCropRequirement);
    assertThat(options.transformations.resizeRequirement).isEqualTo(mockResizeRequirement);
    assertThat(options.transformations.rotateRequirement).isEqualTo(mockRotateRequirement);
  }

  @Test
  public void testToString_whenToString_thenContainsDecodeOptions() {
    final TransformOptions options = TransformOptions.Builder(mockOutputPixelSpecification).build();
    assertThat(options.toString()).contains("TransformOptions");
  }
}

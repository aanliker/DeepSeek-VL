#!/usr/bin/env python

from __future__ import print_function

import json
import os
import sys
import traceback
import torch

# These are the paths to where SageMaker mounts interesting things in your container.
prefix = '/opt/ml/'
input_path = os.path.join(prefix, 'input/data')
output_path = os.path.join(prefix, 'output')
model_path = os.path.join(prefix, 'model')
checkpoints_path = os.path.join(prefix, 'checkpoints')
param_path = os.path.join(prefix, 'input/config/hyperparameters.json')

# default params
default_params = ["--headless", "--log_root", checkpoints_path]


# Execute your training algorithm.
def _run(cmd):
    """Invokes the training algorithm."""

    print(f"Starting training with arguments: {cmd}")

    # To pass dynamic args to get_args, we must modify sys.argv since get_args parses sys.argv
    sys.argv = [sys.argv[0]] + cmd
    args = get_args()

    # Train
    env, env_cfg = task_registry.make_env(name=args.task, args=args)
    ppo_runner, train_cfg = task_registry.make_alg_runner(
        env=env, name=args.task, args=args, log_root=args.log_root)
    ppo_runner.learn(num_learning_iterations=train_cfg.runner.max_iterations,
                     init_at_random_ep_len=True)

    # Export policy
    obs = env.get_observations()
    export_policy_as_onnx(ppo_runner.alg.actor_critic, model_path, os.path.basename(ppo_runner.log_dir), obs[0])
    print('Exported policy as onnxruntime to: ', model_path)


def _hyperparameters_to_cmd_args(hyperparameters):
    """
    Converts our hyperparameters, in json format, into key-value pair suitable for passing to our training
    algorithm.
    """
    cmd_args_list = []

    for key, value in hyperparameters.items():
        cmd_args_list.append(f'--{key}={value}')

    return cmd_args_list


if __name__ == '__main__':
    try:
        # Amazon SageMaker makes our specified hyperparameters available within the
        # /opt/ml/input/config/hyperparameters.json.
        # https://docs.aws.amazon.com/sagemaker/latest/dg/your-algorithms-training-algo.html#your-algorithms-training-algo-running-container
        with open(param_path, 'r') as tc:
            training_params = json.load(tc)

        cmd_args = _hyperparameters_to_cmd_args(training_params)
        _run(default_params + cmd_args)
        print('Training complete.')

        # A zero exit code causes the job to be marked a Succeeded.
        sys.exit(0)
    except Exception as e:
        # Write out an error file. This will be returned as the failureReason in the
        # DescribeTrainingJob result.
        trc = traceback.format_exc()
        with open(os.path.join(output_path, 'failure'), 'w') as s:
            s.write('Exception during training: ' + str(e) + '\n' + trc)
        # Printing this causes the exception to be in the training job logs, as well.
        print('Exception during training: ' + str(e) + '\n' + trc,
              file=sys.stderr)
        # A non-zero exit code causes the training job to be marked as Failed.
        sys.exit(255)

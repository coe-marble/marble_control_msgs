# State samples use one named resource interface per message.
marble_control_msgs/NumericInterface[] state

# Final actuator samples use one named resource interface per message.
marble_control_msgs/NumericInterface[] command

# Controller instances and their flat numeric descriptions.
marble_control_msgs/ControlInterface[] controllers

# Reference-generator instance names and their compact goal layouts.
marble_control_msgs/NumericInterface[] goals

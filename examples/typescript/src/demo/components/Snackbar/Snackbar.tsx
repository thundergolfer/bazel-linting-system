import React from "react";
import Snackbar from "examples/typescript/src/components/Snackbar/Snackbar";

interface ISnackbarDemoState {
  showSnackbar: boolean;
}
export default class SnackbarDemo extends React.Component<
  {},
  ISnackbarDemoState
> {
  constructor(props: {}) {
    super(props);
    this.state = {
      showSnackbar: false
    };
  }

  render() {
    return (
      <div>
        <button
          onClick={() => {
            this.setState({
              showSnackbar: !this.state.showSnackbar
            });
          }}
        >
          Toggle Snackbar
        </button>
        {this.renderSnackbar()}
      </div>
    );
  }

  renderSnackbar() {
    return this.state.showSnackbar ? <Snackbar>hello,bazel!</Snackbar> : null;
  }
}

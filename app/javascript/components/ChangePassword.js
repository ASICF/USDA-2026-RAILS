import React, { useState, useEffect } from "react";
import {
  Button,
  Form,
  Grid,
  Header,
  Image,
  Message,
  Divider,
  Segment,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "./Styles/default";
// import "../other/ChangePassword.css";

export default function ChangePassword(props) {
  const [resetToken, setResetToken] = useState("");
  const [password, setPassword] = useState("");
  // Tracks password error messages
  const [passwordError, setPasswordError] = useState(false);
  const [matchPasswordError, setMatchPasswordError] = useState(false);
  // Tracks valid passwords
  const [validPassword, setValidPassword] = useState(false);
  const [validMatchPassword, setValidMatchPassword] = useState(false);

  useEffect(() => {
    console.log("ChangePassword", props);
    const queryString = window.location.search;
    const urlParams = new URLSearchParams(queryString);

    if (urlParams.get("reset_password_token")) {
      setResetToken(urlParams.get("reset_password_token"));
    } else {
      setResetToken(false);
    }
  }, []);

  const passwordValidate = (e) => {
    // console.log("passwordValidate", e.target.value);

    if (
      e.target.value.search(
        /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,30}$/
      )
    ) {
      setPasswordError(
        "Password must be between 8 and 30 characters, alphanumeric, consist of upper and lower case values, and contain a special character (!@#$%^&*)"
      );
    } else {
      setPassword(e.target.value);
      setValidPassword(true);
      setPasswordError(false);
    }
  };

  const passwordMatch = (e) => {
    // console.log("password match", e.target.value, password);
    if (e.target.value === password) {
      setValidMatchPassword(true);
      setMatchPasswordError(false);
    } else {
      setMatchPasswordError("Passwords do not match");
      setValidMatchPassword(false);
    }
  };

  return (
    <Grid
      textAlign="center"
      style={{
        // height: "100vh",
        marginTop: "2em",
      }}
      verticalAlign="middle"
    >
      <Grid.Column style={{ maxWidth: 450 }}>
        <Header as="h2" textAlign="center">
          Update Password
        </Header>
        <Form
          size="large"
          action="/users/password"
          method="post"
          style={{ textAlign: "left !important" }}
        >
          <Segment stacked style={{ textalign: "left !important" }}>
            {!resetToken && (
              <Message negative>
                <Message.Header>No Reset Token found.</Message.Header>
                <p>
                  Check your email for a link that includes the reset token to
                  update your password.
                </p>
              </Message>
            )}

            <input type="hidden" name="_method" value="put" />
            <input
              type="hidden"
              name="authenticity_token"
              value={props.token}
            />
            <input
              type="hidden"
              name="user[reset_password_token]"
              id="user_reset_password_token"
              value={resetToken}
            />
            <input
              type="hidden"
              name="user[approved]"
              id="user_approved"
              value="1"
            />
            <Form.Input
              fluid
              icon="lock"
              iconPosition="left"
              type="password"
              name="user[password]"
              label="Password"
              onChange={(e) => passwordValidate(e)}
              error={
                passwordError
                  ? {
                      content: passwordError,
                      pointing: "above",
                    }
                  : false
              }
            />
            <Form.Input
              fluid
              icon="lock"
              iconPosition="left"
              type="password"
              name="user[password_confirmation]"
              label="Confirm New Password"
              onChange={(e) => passwordMatch(e)}
              error={
                matchPasswordError
                  ? {
                      content: matchPasswordError,
                      pointing: "above",
                    }
                  : false
              }
            />
            <Button primary fluid size="large">
              Update Password
            </Button>
          </Segment>
        </Form>
      </Grid.Column>
    </Grid>
  );
}
